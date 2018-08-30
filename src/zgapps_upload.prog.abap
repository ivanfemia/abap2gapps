*&---------------------------------------------------------------------*
*& Report  ZGAPPS_UPLOAD
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZGAPPS_UPLOAD.

DATA: lv_file_separator TYPE c,
      input_file_path   TYPE string.

CONSTANTS: lv_default_file_name TYPE string VALUE 'test.xlsx'.

PARAMETERS: lv_wkdir  TYPE string.
PARAMETERS: consumer  TYPE zoauth2_consumer_name,
            username  TYPE zoauth2_user_name,
            proxyhst  TYPE string,
            proxysrv  TYPE string,
            ssl_id    TYPE ssfapplssl DEFAULT 'ANONYM'.



AT SELECTION-SCREEN ON VALUE-REQUEST FOR lv_wkdir.
  cl_gui_frontend_services=>directory_browse( EXPORTING initial_folder  = lv_wkdir
                                              CHANGING  selected_folder = lv_wkdir ).

INITIALIZATION.
  cl_gui_frontend_services=>get_sapgui_workdir( CHANGING sapworkdir = lv_wkdir ).
  cl_gui_cfw=>flush( ).

START-OF-SELECTION.

  cl_gui_frontend_services=>get_file_separator( CHANGING file_separator = lv_file_separator ).

  CONCATENATE lv_wkdir lv_file_separator lv_default_file_name INTO input_file_path.



DATA lt_bin TYPE TABLE OF x255.
DATA: lv_filelength TYPE I.
data: ls_string type string.

 CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = input_file_path
        filetype                = 'BIN'
      IMPORTING
        filelength              = lv_filelength
      CHANGING
        data_tab                = lt_bin
      EXCEPTIONS
        OTHERS                  = 19.
    IF sy-subrc <> 0. "OR lt_bin[] IS INITIAL.
     write / 'Error'.
    ELSE.
      DATA: excel_data TYPE xstring.
      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_filelength
      IMPORTING
        buffer       = excel_data
      TABLES
        binary_tab   = lt_bin
      EXCEPTIONS
          OTHERS       = 2.
      ls_string = excel_data.
*      CALL FUNCTION 'SCMS_BINARY_TO_STRING'
*        EXPORTING
*          input_length = lv_filelength
*        IMPORTING
*          text_buffer  = ls_string
*        TABLES
*          binary_tab   = lt_bin
*        EXCEPTIONS
*          OTHERS       = 2.
      IF sy-subrc <> 0 .
        write / 'Error'.
      ELSE.
        DATA: lo_spreadsheet      TYPE REF TO zcl_docs_spreadsheet.

*          CREATE OBJECT lo_spreadsheet
*            EXPORTING
*              i_consumer_name = consumer
*              i_user_name     = username.

  CREATE OBJECT lo_spreadsheet
    EXPORTING
      i_consumer_name = consumer
      i_user_name     = username
      i_proxy_host    = proxyhst
      i_proxy_service = proxysrv
      i_ssl_id        = ssl_id.

          lo_spreadsheet->zif_docs~UPLOAD(  I_DOCUMENT = excel_data
               I_TITLE = 'demo1' I_SIZE = lv_filelength ).
      ENDIF.
    ENDIF.
    "SPLIT ls_string AT cl_abap_char_utilities=>cr_lf INTO TABLE ex_raw_tab.


*DATA: TEXT2(255),
*      LENG TYPE I,
*      MESS type string.
*
*OPEN DATASET lv_default_file_name FOR INPUT IN TEXT MODE ENCODING DEFAULT MESSAGE MESS.
*IF SY-SUBRC <> 0.
*  WRITE: 'SY-SUBRC:', SY-SUBRC,
*       / 'System Message:', MESS.
*else.
*  DO.
*  READ DATASET lv_default_file_name INTO TEXT2 LENGTH LENG.
*  WRITE: / SY-SUBRC, TEXT2, LENG.
*  IF SY-SUBRC <> 0.
*    EXIT.
*  ENDIF.
*  ENDDO.
*  CLOSE DATASET lv_default_file_name.
*ENDIF.
