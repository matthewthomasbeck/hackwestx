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
import time # import time for M2M token expiry cache
from functools import wraps # import wraps to preserve Flask view metadata
from typing import Any, Callable, Dict, Optional # import typing helpers

##### import third-party libraries #####

import requests # import requests for JWKS and token endpoint calls
from dotenv import load_dotenv # import dotenv to load .env
from flask import jsonify, request # import Flask helpers used by require_auth

##### load environment #####

from pathlib import Path # resolve .env next to application_backend

load_dotenv(Path(__file__).resolve().parent.parent / ".env") # load Auth0-related environment variables





##################################################
############### MODULE STATE #####################
##################################################


########## CREATE LOGGER / TOKEN CACHE ##########

logger = logging.getLogger(__name__) # create module logger

_m2m_token: Optional[str] = None # cached Auth0 M2M access token for predictor calls
_m2m_token_expires_at: float = 0.0 # unix expiry time for cached M2M token





##################################################
############### AUTH0 HELPERS ####################
##################################################


########## AUTH0 DOMAIN ##########

def _auth0_domain(): # function to read and normalize AUTH0_DOMAIN from environment

    domain = os.getenv("AUTH0_DOMAIN", "").rstrip("/") # strip trailing slash
    if not domain: # domain required for JWKS / token URL
        raise ValueError("AUTH0_DOMAIN is not set") # fail fast
    return domain # normalized tenant domain


########## GET JWKS ##########

def get_jwks(): # function to fetch Auth0 JWKS used to verify Flutter user JWTs

    domain = _auth0_domain() # Auth0 tenant host
    url = f"https://{domain}/.well-known/jwks.json" # JWKS endpoint
    logger.debug("Fetching JWKS from %s", url) # log fetch
    # TODO: cache JWKS with TTL
    response = requests.get(url, timeout=10) # GET public keys
    response.raise_for_status() # raise on HTTP error
    return response.json() # JWKS document


########## VALIDATE USER TOKEN ##########

def validate_user_token(token): # function to validate Flutter Bearer token and return JWT claims

    audience = os.getenv("AUTH0_AUDIENCE") # expected JWT audience
    issuer = os.getenv("AUTH0_ISSUER") or f"https://{_auth0_domain()}/" # expected issuer

    if not audience: # audience required
        raise ValueError("AUTH0_AUDIENCE is not set") # fail fast

    # TODO: verify RS256 signature via JWKS, check iss/aud/exp
    # Example (once PyJWT + cryptography are wired):
    #   jwks = get_jwks()
    #   return jwt.decode(token, key=..., audience=audience, issuer=issuer, algorithms=["RS256"])
    logger.warning(
        "validate_user_token() is a skeleton — returning unverified stub claims "
        "(audience=%s issuer=%s token_prefix=%s...)",
        audience,
        issuer,
        token[:12] if token else "",
    ) # warn until real JWT verify is wired
    return {
        "sub": "skeleton|unimplemented",
        "aud": audience,
        "iss": issuer,
    } # unverified stub claims for local wiring


########## REQUIRE AUTH ##########

def require_auth(f): # decorator to require Authorization Bearer user token on Flask routes

    @wraps(f) # preserve original view function name/docs
    def decorated(*args, **kwargs): # wrapped view that enforces Auth0 user auth

        auth_header = request.headers.get("Authorization", "") # read Authorization header
        if not auth_header.startswith("Bearer "): # require Bearer scheme
            return jsonify({
                "error": "Unauthorized",
                "message": "Missing or invalid Authorization header",
            }), 401 # reject missing/malformed header

        token = auth_header.removeprefix("Bearer ").strip() # extract access token
        try:
            claims = validate_user_token(token) # validate (or stub) user JWT
        except Exception as e: # validation failure
            logger.warning("User token validation failed: %s", e) # log reason
            return jsonify({
                "error": "Unauthorized",
                "message": "Invalid access token",
            }), 401 # reject invalid token

        ##### lazy import to avoid circular issues if flask.g unused in scripts #####

        from flask import g # attach claims to request context
        g.user_claims = claims # full claim set
        g.user_sub = claims.get("sub") # subject shortcut
        return f(*args, **kwargs) # proceed to protected view

    return decorated # return wrapped Flask view


########## GET M2M TOKEN ##########

def get_m2m_token(force_refresh=False): # function to get Auth0 client-credentials token for predictor_backend

    global _m2m_token, _m2m_token_expires_at # mutate module token cache

    now = time.time() # current unix time
    if (
        not force_refresh
        and _m2m_token
        and now < (_m2m_token_expires_at - 60)
    ): # reuse cached token with 60s skew
        return _m2m_token # cached access token

    domain = _auth0_domain() # Auth0 tenant
    client_id = os.getenv("AUTH0_M2M_CLIENT_ID") # M2M client id
    client_secret = os.getenv("AUTH0_M2M_CLIENT_SECRET") # M2M client secret
    audience = os.getenv("AUTH0_PREDICTOR_AUDIENCE") # predictor API audience

    if not all([client_id, client_secret, audience]): # all three required
        raise ValueError(
            "AUTH0_M2M_CLIENT_ID, AUTH0_M2M_CLIENT_SECRET, and "
            "AUTH0_PREDICTOR_AUDIENCE must be set"
        ) # fail fast on missing M2M config

    token_url = f"https://{domain}/oauth/token" # Auth0 token endpoint
    payload = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "audience": audience,
    } # client-credentials body

    logger.info("Requesting Auth0 M2M token for predictor audience") # log token request
    response = requests.post(token_url, json=payload, timeout=15) # POST for access token
    response.raise_for_status() # raise on HTTP error
    data = response.json() # token response JSON

    _m2m_token = data["access_token"] # cache access token
    _m2m_token_expires_at = now + float(data.get("expires_in", 3600)) # cache expiry
    return _m2m_token # fresh M2M token
