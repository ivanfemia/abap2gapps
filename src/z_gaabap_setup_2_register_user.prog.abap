*&---------------------------------------------------------------------*
*& Report  Z_OAUTH_SETUP_2_REGISTER_USER
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
*& Step 2:
*& - Register user (run once per user)
*&
*&---------------------------------------------------------------------*

REPORT  z_gaabap_setup_2_register_user.

*--- please adjust if not suits the APIs requirements ---*
CONSTANTS: request_token_url TYPE string
             VALUE '/accounts/OAuthGetRequestToken'
         , authorize_url TYPE string
             VALUE '/accounts/OAuthAuthorizeToken'
         , access_token_url TYPE string
             VALUE '/accounts/OAuthGetAccessToken'
         .

*--------------------------------------------------------------------*
DATA: pin      TYPE string
    , password TYPE string
    .

*--------------------------------------------------------------------*
* selection screen only used in case there exists multiple consumer  *
*--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF SCREEN 9010.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-b02.
PARAMETERS: p_cname TYPE zoauth_consumer_name.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN END OF SCREEN 9010.

*----------------------------------------------------------------------*
*       CLASS lcl_user_setup DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_user_setup DEFINITION.

  PUBLIC SECTION.
    METHODS: constructor
           , request_token
           , access_token
           .

  PRIVATE SECTION.
    DATA: oauth             TYPE REF TO zcl_oauth
        , parameters        TYPE zoauth_key_value_t
        , oauth_error       TYPE REF TO zcx_oauth_error
        , error_text        TYPE string
        , api_host          TYPE zoauth_api_host
        , api_protocol      TYPE string
        , signature_method  TYPE zoauth_signature_method
        .

    METHODS: set_token
               IMPORTING response_data TYPE string
           , authorize
           , save_user_credentials
              IMPORTING response_data TYPE string
           , get_screen_name
              RETURNING value(screen_name) TYPE string
           .

ENDCLASS.                    "lcl_user_setup DEFINITION

*----------------------------------------------------------------------*
*       CLASS screen_handler DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS screen_handler DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-DATA: user_setup TYPE REF TO lcl_user_setup.

    CLASS-METHODS: status_9000
                 , exit_command_9000
                 , user_command_9000
                 .

ENDCLASS.                    "screen_handler DEFINITION

*
*******************
START-OF-SELECTION.
*******************
*

  "*--- selection screen only in case there are multiple consumer registered ---*
  SELECT COUNT( * )
    INTO sy-dbcnt
    FROM zoauth_consumer.

  IF sy-dbcnt > 1.
    CALL SELECTION-SCREEN 9010.
  ENDIF.

  CALL SCREEN 9000
    STARTING AT 10 10.

*----------------------------------------------------------------------*
*       CLASS lcl_user_setup IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_user_setup IMPLEMENTATION.

*--------------------------------------------------------------------*
  METHOD constructor.

    TRY .
        oauth = zcl_oauth=>get_instance( ).
        oauth->read_consumer_pers( p_cname ).
      CATCH zcx_oauth_error INTO oauth_error.
        error_text = oauth_error->get_text( ).
        MESSAGE error_text TYPE 'E'.
    ENDTRY.

    "*--- get API parameters ---*
    api_host             = oauth->get_api_host( ).

    CASE oauth->get_api_protocol( ).
      WHEN 1.
        api_protocol = 'http://'.
      WHEN 2.
        api_protocol = 'https://'.
    ENDCASE.

    signature_method = oauth->get_signature_method( ).

  ENDMETHOD.                    "constructor

*--------------------------------------------------------------------*
  METHOD request_token.

    DATA: url             TYPE string
        , secret          TYPE string
        , response_data   TYPE string
        .

    FIELD-SYMBOLS: <parameter> TYPE LINE OF zoauth_key_value_t.

    "*--- set oauth parameters ---*
    CLEAR parameters.
    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_callback'.
    <parameter>-value = 'oob'.

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_consumer_key'.
    <parameter>-value = oauth->get_consumer_key( ).

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_nonce'.
    <parameter>-value = oauth->create_nonce( 32 ).

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_signature_method'.
    <parameter>-value = 'HMAC-SHA1'.

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_timestamp'.
    <parameter>-value = oauth->create_timestamp( ).

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_version'.
    <parameter>-value = '1.0'.

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'scope'.
    <parameter>-value = 'https%3A%2F%2Fdocs.google.com%2Ffeeds%2F'.

    oauth->set_parameters( parameters ).

    "*--- create new secret ---*
    secret = oauth->get_consumer_secret( ).
    oauth->set_oauth_secret( secret ).

    CONCATENATE
            api_protocol
            api_host
            request_token_url
          INTO url.
    oauth->set_oauth_url( url ).

    oauth->sign_message( method = 'GET' ).

*    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
*    <parameter>-key = 'oauth_signature'.
*    <parameter>-value = oauth->percent_encode( secret ).
*

    "*--- send request and recieve token ---*
    url = request_token_url.

    TRY .
        response_data = oauth->fetchurl( url    = url
                                         method = 'GET' ).
      CATCH zcx_oauth_error INTO oauth_error.
        error_text = oauth_error->get_text( ).
        MESSAGE error_text TYPE 'E'.
    ENDTRY.

    set_token( response_data ).

    "*--- logon to OAuth app and recieve PIN code ---*
    authorize( ).

  ENDMETHOD.                    "request_token

*--------------------------------------------------------------------*
  METHOD set_token.

    DATA: data_t             TYPE string_table
        , dummy              TYPE string
        , oauth_token        TYPE string
        , oauth_token_secret TYPE string
        .

    FIELD-SYMBOLS: <data> TYPE string.

    SPLIT response_data AT '&' INTO TABLE data_t.

    LOOP AT data_t
      ASSIGNING <data>.

      IF <data> CS 'oauth_token='.                          "#EC NOTEXT
        SPLIT <data> AT '=' INTO dummy oauth_token.
      ENDIF.

      IF <data> CS 'oauth_token_secret='.                   "#EC NOTEXT
        SPLIT <data> AT '=' INTO dummy oauth_token_secret.
      ENDIF.

    ENDLOOP.

    IF oauth_token IS INITIAL OR oauth_token_secret IS INITIAL.
      WRITE:/ 'OAuth token is initial'                      "#EC NOTEXT
           ,/ 'Status: error in API, please try again later' "#EC NOTEXT
           .
      RETURN.
    ENDIF.

    oauth->set_oauth_token( oauth_token ).
    oauth->set_oauth_token_secret( oauth_token_secret ).

  ENDMETHOD.                    "set_token

*--------------------------------------------------------------------*
  METHOD authorize.

    DATA: oauth_token TYPE string
        , url         TYPE string
        .

    oauth_token = oauth->get_oauth_token( ).

    "*--- authorize always with SSL ---*
    CONCATENATE
      'https://'                                            "#EC NOTEXT
      api_host
      authorize_url
      '?oauth_token='
      oauth_token
    INTO url.

    cl_gui_frontend_services=>execute(
      EXPORTING
        document               = url
      EXCEPTIONS
        cntl_error             = 1
        error_no_gui           = 2
        bad_parameter          = 3
        file_not_found         = 4
        path_not_found         = 5
        file_extension_unknown = 6
        error_execute_failed   = 7
        synchronous_failed     = 8
        not_supported_by_gui   = 9
        OTHERS                 = 10
        ).

    IF sy-subrc <> 0.
      WRITE:/ 'Probs at execute'.                           "#EC NOTEXT
      RETURN.
    ENDIF.

  ENDMETHOD.                    "authorize

*--------------------------------------------------------------------*
  METHOD access_token.

    DATA: consumer_secret TYPE string
        , token_secret    TYPE string
        , token           TYPE string
        , secret          TYPE string
        , url             TYPE string
        , response_data   TYPE string
        .

    FIELD-SYMBOLS: <parameter> TYPE LINE OF zoauth_key_value_t.

    "*--- set oauth parameters ---*
    CLEAR parameters.

      INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
      <parameter>-key = 'oauth_consumer_key'.                 "#EC NOTEXT
      <parameter>-value = oauth->get_consumer_key( ).

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_nonce'.                        "#EC NOTEXT
    <parameter>-value = oauth->create_nonce( 32 ).

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_signature_method'.             "#EC NOTEXT
    <parameter>-value = 'HMAC-SHA1'.

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_timestamp'.                    "#EC NOTEXT
    <parameter>-value = oauth->create_timestamp( ).

    token = oauth->get_oauth_token( ).
    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_token'.                        "#EC NOTEXT
    <parameter>-value = token.

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_verifier'.                     "#EC NOTEXT
    <parameter>-value = pin.

    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
    <parameter>-key = 'oauth_version'.
    <parameter>-value = '1.0'.

*    INSERT INITIAL LINE INTO TABLE parameters ASSIGNING <parameter>.
*    <parameter>-key = 'oauth_callback'.
*    <parameter>-value = 'oob'.

    oauth->set_parameters( parameters ).

    "*--- create new secret ---*
    consumer_secret = oauth->get_consumer_secret( ).
    token_secret    = oauth->get_oauth_token_secret( ).

    CONCATENATE
      consumer_secret
      token_secret
    INTO secret.

    oauth->set_oauth_secret( secret ).

    CONCATENATE
      api_protocol
      api_host
      access_token_url
    INTO url.

    oauth->set_oauth_url( url ).
    oauth->sign_message( method = 'GET' ).

    "*--- send request and recieve token ---*
    url = access_token_url.

    TRY .
        response_data = oauth->fetchurl( url    = url
                                         method = 'GET' ).
      CATCH zcx_oauth_error INTO oauth_error.
        error_text = oauth_error->get_text( ).
        MESSAGE error_text TYPE 'E'.
    ENDTRY.

    "*--- save user credentials --*
    save_user_credentials( response_data ).

  ENDMETHOD.                    "access_token

*--------------------------------------------------------------------*
  METHOD save_user_credentials.

    DATA: data_t             TYPE string_table
        , dummy              TYPE string
        , oauth_token        TYPE string
        , oauth_token_secret TYPE string
        , screen_name        TYPE string
        , message            TYPE string
        .

    FIELD-SYMBOLS: <data> TYPE string.

    SPLIT response_data AT '&' INTO TABLE data_t.

    LOOP AT data_t
      ASSIGNING <data>.

      IF <data> CS 'oauth_token='.                          "#EC NOTEXT
        SPLIT <data> AT '=' INTO dummy oauth_token.
      ENDIF.

      IF <data> CS 'oauth_token_secret='.                   "#EC NOTEXT
        SPLIT <data> AT '=' INTO dummy oauth_token_secret.
      ENDIF.

      IF <data> CS 'screen_name='.                          "#EC NOTEXT
        SPLIT <data> AT '=' INTO dummy screen_name.
      ENDIF.

    ENDLOOP.

    IF oauth_token IS INITIAL
    OR oauth_token_secret IS INITIAL.
      MESSAGE 'API error: OAuth token is initial' TYPE 'E'.
    ENDIF.

    "*--- some providers (e.g. Streamwork) don't deliver the user name ---*
    IF screen_name IS INITIAL.
      screen_name = get_screen_name( ).

      IF screen_name IS INITIAL.  "still initial
        MESSAGE 'Values cannot be saved: User name not entered' TYPE 'E'.
      ENDIF.
    ENDIF.

    oauth->set_user_pers(
      consumer_name      = p_cname
      screen_name        = screen_name
      password           = password
      oauth_token        = oauth_token
      oauth_token_secret = oauth_token_secret
      ).

    CONCATENATE
      'Credentials for User'                                "#EC NOTEXT
      screen_name
      'successfully saved'                                  "#EC NOTEXT
    INTO message SEPARATED BY space.

    MESSAGE message TYPE 'I'.

  ENDMETHOD.                    "save_user_credentials

*--------------------------------------------------------------------*
  METHOD get_screen_name.

    DATA: fields TYPE TABLE OF sval
        , title  TYPE string
        .

    FIELD-SYMBOLS: <field> TYPE sval.

    title = 'Please enter a unique user name'(t01).

    INSERT INITIAL LINE INTO TABLE fields ASSIGNING <field>.
    <field>-tabname     = 'ZOAUTH_USER'.                    "#EC NOTEXT
    <field>-fieldname   = 'USER_NAME'.                      "#EC NOTEXT
    <field>-field_attr  = '00'.                      "input "#EC NOTEXT

    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        popup_title = title
      TABLES
        fields      = fields
      EXCEPTIONS
        OTHERS      = 0.

    READ TABLE fields INDEX 1
      ASSIGNING <field>.

    IF <field> IS ASSIGNED.
      screen_name = <field>-value.
    ENDIF.

  ENDMETHOD.                    "get_screen_name

ENDCLASS.                    "lcl_user_setup IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS screen_handler IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS screen_handler IMPLEMENTATION.

*--------------------------------------------------------------------*
  METHOD status_9000.

    IF sy-pfkey <> '9000'.

      CREATE OBJECT user_setup.
      user_setup->request_token( ).

      SET PF-STATUS '9000'.
      SET TITLEBAR '9000'.
    ENDIF.

  ENDMETHOD.                    "status_9000

*--------------------------------------------------------------------*
  METHOD exit_command_9000.

    LEAVE TO SCREEN 0.

  ENDMETHOD.                    "EXIT_COMMAND_9000

*--------------------------------------------------------------------*
  METHOD user_command_9000.

    DATA: lv_ucomm TYPE syucomm.

    lv_ucomm = sy-ucomm.
    CLEAR sy-ucomm.

    IF lv_ucomm = 'SAVE'.
      user_setup->access_token( ).
      LEAVE TO SCREEN 0.
    ENDIF.

  ENDMETHOD.                    "user_command_9000

ENDCLASS.                    "screen_handler IMPLEMENTATION

*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9000 OUTPUT.

  screen_handler=>status_9000( ).

ENDMODULE.                 " STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_9000 INPUT.

  screen_handler=>exit_command_9000( ).

ENDMODULE.                 " EXIT_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.

  screen_handler=>user_command_9000( ).

ENDMODULE.                 " USER_COMMAND_9000  INPUT
