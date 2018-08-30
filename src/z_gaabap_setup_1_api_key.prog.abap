*&---------------------------------------------------------------------*
*& Report  Z_OAUTH_SETUP_1_API_KEY
*&
*&---------------------------------------------------------------------*

*--------------------------------------------------------------------*
*
* The OAuth library (Part of "Twibap: The ABAP Twitter API")
* Copyright (C) 2010 Uwe Fetzer + SAP Developer Network members
*
* Project home: http://twibap.googlecode.com
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*--------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&
*& Step 1:
*& - register your application (e.g. at http://dev.twitter.com/apps)
*& - store consumer keys in SAP (this report)
*&
*&---------------------------------------------------------------------*

REPORT  z_gaabap_setup_1_api_key.

*--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-b01.
PARAMETERS: p_key    TYPE zoauth_consumer_key LOWER CASE OBLIGATORY DEFAULT 'anonymous'
          , p_secret TYPE zoauth_consumer_secret LOWER CASE OBLIGATORY DEFAULT 'anonymous'
          , p_host   TYPE zoauth_api_host LOWER CASE OBLIGATORY
          .

SELECTION-SCREEN SKIP.

"*--- in case of multiple consumer per system (unique consumer name) ---*
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-b02.
PARAMETERS: p_name   TYPE zoauth_consumer_name.
SELECTION-SCREEN END OF BLOCK b2.

"*--- API protocol ---*
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-b03.
PARAMETERS: p_http  RADIOBUTTON GROUP b3
          , p_https RADIOBUTTON GROUP b3
          .
SELECTION-SCREEN END OF BLOCK b3.

"*--- Signature Method ---*
SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE text-b04.
PARAMETERS: p_hmac   RADIOBUTTON GROUP b4
          , p_plain  RADIOBUTTON GROUP b4
          .
SELECTION-SCREEN END OF BLOCK b4.

SELECTION-SCREEN END OF BLOCK b1.
*--------------------------------------------------------------------*

DATA: api_protocol     TYPE zoauth_api_protocol
    , signature_method TYPE zoauth_signature_method
    .

*--- transform values ---*
CASE 'X'.
  WHEN p_http.
    api_protocol = 1.
  WHEN p_https.
    api_protocol = 2.
ENDCASE.

CASE 'X'.
  WHEN p_plain.
    signature_method = 0.
  WHEN p_hmac.
    signature_method = 1.
ENDCASE.

*--- set consumer key and secret persistant ---*
zcl_oauth=>set_consumer_pers(
  consumer_name         = p_name
  oauth_consumer_key    = p_key
  oauth_consumer_secret = p_secret
  signature_method      = signature_method
  api_host              = p_host
  api_protocol          = api_protocol
  ).

MESSAGE 'Keys stored successfully'(m01) TYPE 'I'.
