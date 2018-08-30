*&---------------------------------------------------------------------*
*& Report  ZGAPPS_GET_DOCS_LIST
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zgapps_get_docs_list.

DATA: lo_spreadsheet      TYPE REF TO zcl_docs_spreadsheet,
      lo_spreadsheet_item TYPE REF TO zcl_docs_spreadsheet,
      lo_iterator         TYPE REF TO cl_object_collection_iterator.

PARAMETERS: consumer      TYPE zoauth2_consumer_name,
            username      TYPE zoauth2_user_name,
            proxyhst      TYPE string,
            proxysrv      TYPE string,
            ssl_id        TYPE ssfapplssl DEFAULT 'ANONYM'.

START-OF-SELECTION.

  CREATE OBJECT lo_spreadsheet
    EXPORTING
      i_consumer_name = consumer
      i_user_name     = username
      i_proxy_host    = proxyhst
      i_proxy_service = proxysrv
      i_ssl_id        = ssl_id.

  lo_spreadsheet->zif_docs~get_list( ).

  lo_iterator = lo_spreadsheet->zif_docs~doc_list->get_iterator( ).
  WHILE lo_iterator->if_object_collection_iterator~has_next( ) EQ abap_true.
    lo_spreadsheet_item ?= lo_iterator->if_object_collection_iterator~get_next( ).
    WRITE lo_spreadsheet_item->zif_docs~title.
    SKIP 1.
  ENDWHILE.
