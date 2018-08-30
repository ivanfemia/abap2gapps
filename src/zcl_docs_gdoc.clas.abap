class ZCL_DOCS_GDOC definition
  public
  final
  create public .

*"* public components of class ZCL_DOCS_GDOC
*"* do not include other source files here!!!
public section.

  constants C_OAUTH2_NATIVE_APP type ZOAUTH2_SIGNATURE_METHOD value '3'. "#EC NOTEXT
  data PROXY_HOST type STRING .
  data PROXY_SERVICE type STRING .
  data SSL_ID type SSFAPPLSSL value 'ANONYM'. "#EC NOTEXT .

  methods CONSTRUCTOR
    importing
      !I_CONSUMER_NAME type ZOAUTH2_CONSUMER_NAME
      !I_USER_NAME type ZOAUTH2_USER_NAME optional
      !I_PROXY_HOST type STRING optional
      !I_PROXY_SERVICE type STRING optional
      !I_SSL_ID type SSFAPPLSSL default 'ANONYM' .
  methods UPLOAD_SPREADSHEET
    importing
      !I_DOCUMENT type XSTRING
      !I_TITLE type STRING
      !I_SIZE type I
    returning
      value(O_API_RESPONSE) type ZOAUTH2_API_RESPONSE
    raising
      ZCX_DOCS_GDOC_ERROR
      ZCX_OAUTH2_ERROR .
  methods CREATE_SPREADSHEET
    returning
      value(O_API_RESPONSE) type ZOAUTH2_API_RESPONSE .
  methods GET_SPREADSHEET_LIST
    returning
      value(O_API_RESPONSE) type ZOAUTH2_API_RESPONSE
    raising
      ZCX_DOCS_GDOC_ERROR .
protected section.
*"* protected components of class ZCL_DOCS_GDOC
*"* do not include other source files here!!!

  methods CALL_API
    importing
      !I_API_URI type ZOAUTH2_API_HOST
      !I_API_HOST type ZOAUTH2_HOST
      !I_API_METHOD type STRING
      !I_API_REQUEST type ZOAUTH2_API_REQUEST optional
      !I_DOCUMENT type XSTRING optional
    exporting
      value(O_API_RESPONSE) type ZOAUTH2_API_RESPONSE
    changing
      !C_HEADER_FIELDS type TIHTTPNVP optional
    raising
      ZCX_DOCS_GDOC_ERROR
      ZCX_OAUTH2_ERROR .
private section.
*"* private components of class ZCL_DOCS_GDOC
*"* do not include other source files here!!!

  constants API_HOST type ZOAUTH2_API_HOST value 'spreadsheets.google.com'. "#EC NOTEXT
  constants API_HOST_DOCS type ZOAUTH2_API_HOST value 'docs.google.com'. "#EC NOTEXT
  constants API_LIST_SPREADSHEETS type ZOAUTH2_API_HOST value '/feeds/spreadsheets/private/full'. "#EC NOTEXT
  constants API_RESPONSE_TYPE type STRING value 'json'. "#EC NOTEXT
  constants API_URI_DOCS type ZOAUTH2_API_HOST value '/feeds/default/private/full'. "#EC NOTEXT
  constants AUTHORIZATION_HOST type ZOAUTH2_HOST value 'https://accounts.google.com/o/oauth2/auth'. "#EC NOTEXT
  data CONSUMER_NAME type ZOAUTH2_CONSUMER_NAME .
  data OAUTH2 type ref to ZIF_OAUTH2 .
  constants RET_REFRESH_TOKEN_HOST type ZOAUTH2_HOST value 'www.google.com'. "#EC NOTEXT
  constants RET_REFRESH_TOKEN_REQUEST_URI type ZOAUTH2_HOST value '/accounts/o8/oauth2/token'. "#EC NOTEXT
  constants RET_REFRESH_TOKEN_URL type ZOAUTH2_HOST value 'https://accounts.google.com/o/oauth2/token'. "#EC NOTEXT
  data SCOPE type ZOAUTH2_HOST .
  data TOKEN type ZOAUTH2_TOKEN .
  data USER_NAME type ZOAUTH2_USER_NAME .

  methods GET_SPREADSHEET .
  methods GET_WORKSHEET .
ENDCLASS.



CLASS ZCL_DOCS_GDOC IMPLEMENTATION.


method CALL_API.
  DATA: client TYPE REF TO if_http_client,
      lv_request_uri TYPE string,
      lv_rc TYPE i,
       lv_json_doc TYPE REF TO zcl_json_document,
      wa_header_fields TYPE ihttpnvp,
      lv_auth TYPE  string.



  MOVE i_api_uri  TO lv_request_uri.

  CONCATENATE 'OAuth' token INTO lv_auth SEPARATED BY space.

  wa_header_fields-name = 'Authorization'.
  wa_header_fields-value  = lv_auth.
  APPEND wa_header_fields TO c_header_fields.

  IF api_response_type IS NOT INITIAL.
    CONCATENATE lv_request_uri '?alt=' api_response_type INTO lv_request_uri.
  ENDIF.

  IF i_api_method = oauth2->co_request_method_get AND i_api_request IS NOT INITIAL.
    CONCATENATE lv_request_uri '&' i_api_request INTO lv_request_uri.
  ENDIF.


  CALL METHOD cl_http_client=>create
    EXPORTING
      host               = i_api_host
      proxy_host         = me->proxy_host
      proxy_service      = me->proxy_service
      ssl_id             = me->ssl_id
      scheme             = cl_http_client=>schemetype_https
*     sap_username       =
*     sap_client         =
    IMPORTING
      client             = client
    EXCEPTIONS
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      OTHERS             = 4.
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  client->propertytype_logon_popup = client->co_disabled.

  CALL METHOD cl_http_utility=>if_http_utility~set_request_uri
    EXPORTING
      request = client->request
      uri     = lv_request_uri.

  CALL METHOD client->request->set_method
    EXPORTING
      method = i_api_method.

  CALL METHOD client->request->set_version
    EXPORTING
      version = '1001'.

  CALL METHOD client->request->if_http_entity~set_header_field
    EXPORTING
      name  = 'GData-Version'
      value = '3.0'.

  IF c_header_fields IS NOT INITIAL.
    LOOP AT c_header_fields INTO wa_header_fields.
      CALL METHOD client->request->if_http_entity~set_header_field
        EXPORTING
          name  = wa_header_fields-name
          value = wa_header_fields-value.

    ENDLOOP.

  ENDIF.

  IF i_api_method = oauth2->co_request_method_post.
    IF i_document IS NOT INITIAL.
      CALL METHOD client->request->if_http_entity~set_data
        EXPORTING
          data = i_document.
    ELSEIF i_api_request IS NOT INITIAL.
      CALL METHOD client->request->if_http_entity~set_cdata
        EXPORTING
          data = i_api_request.
    ENDIF.

  ENDIF.

  CALL METHOD client->send
*    EXPORTING
*      timeout                    = 30
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      http_invalid_timeout       = 4
      OTHERS                     = 5
          .
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL METHOD client->receive
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  client->response->get_status( IMPORTING code = lv_rc ).

  CALL METHOD client->response->get_cdata
    RECEIVING
      data = o_api_response.

  CALL METHOD client->response->if_http_entity~get_header_fields
    CHANGING
      fields = c_header_fields.

*  IF wa_header_fields-value NE co_document_created.
*    IF wa_header_fields-value EQ co_conversion_error.

  IF lv_rc EQ 401.

    READ TABLE c_header_fields INTO wa_header_fields WITH TABLE KEY name = '~status_reason'.

    IF wa_header_fields-value EQ 'Token invalid - Invalid AuthSub token.'.
      RAISE EXCEPTION TYPE zcx_oauth2_error.

    ENDIF.



** Se il token è ok generare eccezione ZCX_OAUTH2_ERROR '401'
  ENDIF.
endmethod.


method CONSTRUCTOR.

  DATA: lv_method TYPE i.

  me->consumer_name = i_consumer_name.
  me->proxy_host    = i_proxy_host.
  me->proxy_service = i_proxy_service.
  me->ssl_id        = i_ssl_id.

  SELECT SINGLE signature_method INTO lv_method FROM zoauth2_consumer WHERE consumer_name = i_consumer_name.

  CASE lv_method.
    WHEN c_oauth2_native_app.
      CREATE OBJECT oauth2
        TYPE
          zcl_oauth2_native_app
        EXPORTING
          i_user_name                  = i_user_name
          i_consumer_name              = i_consumer_name
          i_auth_host                  = authorization_host
          i_ret_refresh_token_host     = ret_refresh_token_host
          i_ret_refresh_token_requ_uri = ret_refresh_token_request_uri
          i_ret_refresh_token_url      = ret_refresh_token_url.

    WHEN OTHERS.
  ENDCASE.

  CALL METHOD oauth2->get_access_token
    RECEIVING
      token = token.


endmethod.


method CREATE_SPREADSHEET.

  DATA: lv_token TYPE zoauth2_token,
        lv_api_url TYPE zoauth2_api_host.

*  lv_token = me->zif_oauth2~get_access_token( ).



endmethod.


method GET_SPREADSHEET.
endmethod.


method GET_SPREADSHEET_LIST.

  DATA: lv_token TYPE zoauth2_token,
        lv_api_url TYPE zoauth2_api_host.


  TRY .

      CALL METHOD me->call_api
        EXPORTING
          i_api_uri      = api_list_spreadsheets
          i_api_host     = api_host
          i_api_method   = zcl_oauth2_native_app=>zif_oauth2~co_request_method_get
        IMPORTING
          o_api_response = o_api_response.

    CATCH zcx_oauth2_error.

      token = oauth2->refresh_access_token( ).

      CALL METHOD me->call_api
        EXPORTING
          i_api_uri      = api_list_spreadsheets
          i_api_host     = api_host
          i_api_method   = zcl_oauth2_native_app=>zif_oauth2~co_request_method_get
        IMPORTING
          o_api_response = o_api_response.


  ENDTRY.




endmethod.


method GET_WORKSHEET.
endmethod.


method UPLOAD_SPREADSHEET.

  DATA: lt_header_fields TYPE tihttpnvp,
        lt_header_fields_tmp TYPE tihttpnvp,
        wa_header_fields TYPE ihttpnvp,
        lv_auth TYPE string.

  CONSTANTS: co_conversion_error TYPE i VALUE 400,
  co_document_created TYPE i VALUE 201.

  wa_header_fields-name = 'Content-Length'.
  wa_header_fields-value  = I_SIZE.

  APPEND wa_header_fields TO lt_header_fields.

  wa_header_fields-name = 'Content-Type'.
  wa_header_fields-value  = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
  "wa_header_fields-value  = 'application/vnd.ms-excel'.

  APPEND wa_header_fields TO lt_header_fields.

  wa_header_fields-name = 'Slug'.
  wa_header_fields-value  = i_title.

  APPEND wa_header_fields TO lt_header_fields.

  lt_header_fields_tmp = lt_header_fields.

  TRY .

      CALL METHOD me->call_api
        EXPORTING
          i_api_uri       = api_uri_docs
          i_api_host      = api_host_docs
          i_api_method    = zcl_oauth2_native_app=>zif_oauth2~co_request_method_post
          i_document      = i_document
        IMPORTING
          o_api_response  = o_api_response
        CHANGING
          c_header_fields = lt_header_fields.


    CATCH zcx_oauth2_error.

      token = oauth2->refresh_access_token( ).

      CALL METHOD me->call_api
        EXPORTING
          i_api_uri       = api_uri_docs
          i_api_host      = api_host_docs
          i_api_method    = zcl_oauth2_native_app=>zif_oauth2~co_request_method_post
          i_document      = i_document
        IMPORTING
          o_api_response  = o_api_response
        CHANGING
          c_header_fields = lt_header_fields_tmp.

  ENDTRY.

  READ TABLE lt_header_fields INTO wa_header_fields WITH KEY name = '~response_code'.
if sy-subrc eq 0.
  IF wa_header_fields-value NE co_document_created.
    IF wa_header_fields-value EQ co_conversion_error.
      RAISE EXCEPTION TYPE ZCX_DOCS_GDOC_ERROR
*          EXPORTING
*            textid =
*            previous =
*            api_response =
          .
    ENDIF.
  ENDIF.
ENDIF.










endmethod.
ENDCLASS.
