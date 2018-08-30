*&---------------------------------------------------------------------*
*& Report  ZDEMO_EXCEL1
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zdemo_excel_gapps.

DATA: lo_excel                TYPE REF TO zcl_excel,
      lo_excel_writer         TYPE REF TO zif_excel_writer,
      lo_worksheet            TYPE REF TO zcl_excel_worksheet,
      lo_hyperlink            TYPE REF TO zcl_excel_hyperlink,
      column_dimension        TYPE REF TO zcl_excel_worksheet_columndime.

DATA: lv_file                 TYPE xstring,
      lv_bytecount            TYPE i.


PARAMETERS: consumer  TYPE  zoauth2_consumer_name default 'ABAP2GAPPSCI3',
            username  TYPE  zoauth2_user_name default 'TEST01'.


START-OF-SELECTION.


  " Creates active sheet
  CREATE OBJECT lo_excel.

  " Get active sheet
  lo_worksheet = lo_excel->get_active_worksheet( ).
  lo_worksheet->set_title( ip_title = 'Sheet1' ).
  lo_worksheet->set_cell( ip_column = 'B' ip_row = 2 ip_value = 'Hello world' ).
  lo_worksheet->set_cell( ip_column = 'B' ip_row = 3 ip_value = sy-datum ).
  lo_worksheet->set_cell( ip_column = 'C' ip_row = 3 ip_value = sy-uzeit ).
  lo_hyperlink = zcl_excel_hyperlink=>create_external_link( iv_url = 'https://cw.sdn.sap.com/cw/groups/abap2xlsx' ).
  lo_worksheet->set_cell( ip_column = 'B' ip_row = 4 ip_value = 'Click here to visit abap2xlsx homepage' ip_hyperlink = lo_hyperlink ).

  column_dimension = lo_worksheet->get_column_dimension( ip_column = 'B' ).
  column_dimension->set_width( ip_width = 11 ).

  CREATE OBJECT lo_excel_writer TYPE zcl_excel_writer_2007.
  lv_file = lo_excel_writer->write_file( lo_excel ).

  " Save the file ONLINE
  DATA: lo_spreadsheet      TYPE REF TO zcl_docs_spreadsheet.
  CREATE OBJECT lo_spreadsheet
            EXPORTING
              i_consumer_name = consumer
              i_user_name     = username.

  lv_bytecount  = XSTRLEN( lv_file ).

          lo_spreadsheet->zif_docs~UPLOAD(  I_DOCUMENT = lv_file
               I_TITLE = 'demo1froma2xlsx' I_SIZE = lv_bytecount ).
