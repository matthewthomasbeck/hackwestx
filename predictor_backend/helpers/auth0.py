##################################################################################
# Copyright (c) 2026 Matthew Thomas Beck                                         #
#                                                                                #
# Licensed under the Creative Commons Attribution-NonCommercial 4.0              #
# International (CC BY-NC 4.0). Personal and educational use is permitted.       #
# Commercial use by companies or for-profit entities is prohibited.              #
##################################################################################





############################################################
############### IMPORT / CREATE DEPENDENCIES ###############
############################################################


########## IMPORT DEPENDENCIES ##########

##### import necessary libraries #####

from __future__ import annotations # enable postponed evaluation of type hints

import logging # import logging for Auth0 helper messages
import os # import os for Auth0 env vars
from functools import wraps # import wraps to preserve Flask view metadata
from pathlib import Path # import Path to load predictor_backend/.env regardless of cwd
from typing import Any, Dict, Optional # import typing helpers

##### import third-party libraries #####

import jwt # import PyJWT for RS256 access-token verification
from dotenv import load_dotenv # import dotenv to load .env
from flask import g, jsonify, request # import Flask helpers used by require_m2m_auth
from jwt import PyJWKClient # import PyJWKClient for Auth0 JWKS key lookup

##### load environment #####

load_dotenv(Path(__file__).resolve().parent.parent / ".env") # load predictor_backend/.env





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER / JWKS CACHE ##########

logger = logging.getLogger("prediction_service") # create module logger aligned with service name

_jwks_client: Optional[PyJWKClient] = None # cached PyJWKClient for Auth0 JWKS
_jwks_client_domain: Optional[str] = None # domain the cached client was built for
_JWKS_TTL_SECONDS = 3600 # refresh JWKS client hourly





##################################################
############### AUTH0 M2M HELPERS ################
##################################################


########## AUTH0 DOMAIN ##########

def _auth0_domain(): # function to read and normalize AUTH0_DOMAIN from environment

    domain = (os.getenv("AUTH0_DOMAIN") or "").strip().rstrip("/") # strip whitespace / slash
    if domain.startswith("https://"): # allow full issuer-style values
        domain = domain[len("https://"):] # keep host only
    if domain.startswith("http://"): # allow http form
        domain = domain[len("http://"):] # keep host only
    if not domain: # domain required for JWKS / issuer
        raise ValueError("AUTH0_DOMAIN is not set") # fail fast
    return domain # e.g. soothsayer-dev.us.auth0.com


########## AUTH0 AUDIENCE ##########

def _auth0_audience(): # function to read predictor API audience (M2M tokens)

    audience = (os.getenv("AUTH0_AUDIENCE") or "").strip() # expected aud claim
    if not audience: # audience required
        raise ValueError("AUTH0_AUDIENCE is not set") # fail fast
    return audience # e.g. https://predictor.soothsayer.hackwestx


########## AUTH0 ISSUER ##########

def _auth0_issuer(): # function to read expected JWT issuer (defaults to https://{domain}/)

    issuer = (os.getenv("AUTH0_ISSUER") or "").strip() # optional explicit issuer
    if issuer: # configured
        return issuer if issuer.endswith("/") else f"{issuer}/" # Auth0 issuer has trailing slash
    return f"https://{_auth0_domain()}/" # standard Auth0 issuer


########## GET JWKS CLIENT ##########

def get_jwks_client(force_refresh=False): # function to return a cached PyJWKClient for Auth0 JWKS

    global _jwks_client, _jwks_client_domain # mutate module cache

    domain = _auth0_domain() # Auth0 tenant host
    if (
        force_refresh
        or _jwks_client is None
        or _jwks_client_domain != domain
    ): # rebuild client when missing / domain changed
        jwks_url = f"https://{domain}/.well-known/jwks.json" # JWKS endpoint
        logger.info("Creating Auth0 JWKS client for %s", jwks_url) # log once per rebuild
        _jwks_client = PyJWKClient(jwks_url, cache_keys=True, lifespan=_JWKS_TTL_SECONDS) # cached keys
        _jwks_client_domain = domain # remember domain

    return _jwks_client # ready client


########## GET JWKS ##########

def get_jwks(force_refresh=False): # function to fetch Auth0 JWKS used to verify M2M access tokens

    # Kept for debugging / parity with application_backend; validation uses PyJWKClient
    client = get_jwks_client(force_refresh=force_refresh) # ensure client exists
    domain = _auth0_domain() # tenant
    url = f"https://{domain}/.well-known/jwks.json" # JWKS URL
    # PyJWKClient does not expose the raw doc easily — fetch for inspect/debug
    import requests # local import to keep cold path light

    logger.debug("Fetching raw JWKS from %s", url) # log fetch
    response = requests.get(url, timeout=10) # GET public keys
    response.raise_for_status() # raise on HTTP error
    if force_refresh: # caller asked for refresh
        get_jwks_client(force_refresh=True) # rebuild client too
    _ = client # silence unused if only raw fetch wanted
    return response.json() # JWKS document


########## VALIDATE M2M TOKEN ##########

def validate_m2m_token(token): # function to validate application_backend Auth0 M2M Bearer JWT

    if not token: # empty bearer
        raise ValueError("Missing access token") # reject

    audience = _auth0_audience() # predictor API audience
    issuer = _auth0_issuer() # expected iss
    client = get_jwks_client() # JWKS-backed key client

    try:
        signing_key = client.get_signing_key_from_jwt(token) # match kid → public key
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=audience,
            issuer=issuer,
            options={"require": ["exp", "iat", "sub"]},
        ) # verified claims
    except jwt.PyJWTError as exc: # signature / aud / iss / exp failures
        logger.warning("M2M JWT validation failed: %s", exc) # no token logged
        raise ValueError(f"Invalid M2M access token: {exc}") from exc # surface to decorator

    # Optional: prefer client-credentials tokens (gty) when Auth0 includes it
    gty = claims.get("gty") # grant type claim (often "client-credentials")
    if gty and gty != "client-credentials": # unexpected grant
        raise ValueError(f"Unexpected grant type for predictor M2M token: {gty}") # reject

    # Optional scope check when RBAC permissions are present in the token
    permissions = claims.get("permissions") or claims.get("scope") or "" # list or space string
    if isinstance(permissions, str): # scope string
        perm_set = set(permissions.split()) # tokenize
    else: # list of permissions
        perm_set = set(permissions) # as set
    if perm_set and "predict:run" not in perm_set: # API granted a permission set without predict:run
        raise ValueError("M2M token missing predict:run permission") # reject

    logger.debug(
        "M2M token accepted (sub=%s aud=%s)",
        claims.get("sub"),
        claims.get("aud"),
    ) # success without dumping token
    return claims # verified claims for request context


########## REQUIRE M2M AUTH ##########

def require_m2m_auth(f): # decorator to require Authorization Bearer M2M token on predict routes

    @wraps(f) # preserve original view function name/docs
    def decorated(*args, **kwargs): # wrapped view that enforces Auth0 M2M auth

        auth_header = request.headers.get("Authorization", "") # read Authorization header
        if not auth_header.startswith("Bearer "): # require Bearer scheme
            return jsonify({
                "error": "Unauthorized",
                "message": "Missing or invalid Authorization header",
            }), 401 # reject missing/malformed header

        token = auth_header.removeprefix("Bearer ").strip() # extract access token
        try:
            claims = validate_m2m_token(token) # verify RS256 JWT via Auth0 JWKS
        except Exception as e: # validation failure
            logger.warning("M2M token validation failed: %s", e) # log reason
            return jsonify({
                "error": "Unauthorized",
                "message": "Invalid M2M access token",
            }), 401 # reject invalid token

        g.m2m_claims = claims # full claim set
        g.m2m_sub = claims.get("sub") # client subject shortcut
        request.m2m_claims = claims # type: ignore[attr-defined]  # parity with verify_api_key
        return f(*args, **kwargs) # proceed to protected view

    return decorated # return wrapped Flask view
