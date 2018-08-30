class ZCL_DOCS_SPREADSHEET definition
  public
  inheriting from ZCL_DOCS
  final
  create public .

public section.
*"* public components of class ZCL_DOCS_SPREADSHEET
*"* do not include other source files here!!!

  interfaces ZIF_DOCS_SPREADSHEET .

  methods ZIF_DOCS~GET_LIST
    redefinition .
  methods ZIF_DOCS~UPLOAD
    redefinition .
protected section.
*"* protected components of class ZCL_DOCS_SPREADSHEET
*"* do not include other source files here!!!

  methods NEW_DOC_FROM_JSON
    redefinition .
private section.
*"* private components of class ZCL_DOCS_SPREADSHEET
*"* do not include other source files here!!!

  methods FROM_GENERIC_DOC
    importing
      !IO_DOC type ref to ZIF_DOCS .
ENDCLASS.



CLASS ZCL_DOCS_SPREADSHEET IMPLEMENTATION.


method FROM_GENERIC_DOC.

  DATA: lo_obj TYPE REF TO cl_oo_object,
        lo_doc TYPE REF TO zcl_docs.

  DATA: lt_attrs      TYPE seo_attributes,
        ls_attr       TYPE vseoattrib,
        lv_attribute  TYPE string.

  FIELD-SYMBOLS: <source> TYPE any,
                 <target> TYPE any.
  lo_obj = cl_oo_object=>get_instance( clsname = 'ZIF_DOCS' ).

  lt_attrs = lo_obj->get_attributes( public_attributes_only    = seox_false
                                     instance_attributes_only  = seox_false
                                     reference_attributes_only = seox_false ).

  lo_doc ?= io_doc.
  " for each attribute excluding constants
  LOOP AT lt_attrs INTO ls_attr WHERE attdecltyp NE 2.
    CONCATENATE 'me->zif_docs~' ls_attr-cmpname INTO lv_attribute RESPECTING BLANKS.
    ASSIGN (lv_attribute)             TO <target>.
    ASSIGN io_doc->(ls_attr-cmpname)  TO <source>.
    CASE ls_attr-exposure.
      WHEN 0. "Private
      WHEN 1. "Protected
        <target> = <source>.
      WHEN 2. "Public
        <target> = <source>.
      WHEN 3. "Package
    ENDCASE.
  ENDLOOP.

  lo_obj = cl_oo_object=>get_instance( clsname = 'ZCL_DOCS' ).

  lt_attrs = lo_obj->get_attributes( public_attributes_only    = seox_false
                                     instance_attributes_only  = seox_false
                                     reference_attributes_only = seox_false ).

  lo_doc ?= io_doc.
  " for each attribute excluding constants
  LOOP AT lt_attrs INTO ls_attr WHERE attdecltyp NE 2.
    ASSIGN me->(ls_attr-cmpname)     TO <target>.
    ASSIGN lo_doc->(ls_attr-cmpname) TO <source>.
    CASE ls_attr-exposure.
      WHEN 0. "Private
      WHEN 1. "Protected
        <target> = <source>.
      WHEN 2. "Public
        <target> = <source>.
      WHEN 3. "Package
    ENDCASE.
  ENDLOOP.

endmethod.


method NEW_DOC_FROM_JSON.

  DATA: lo_doc             TYPE REF TO zif_docs,
        lo_doc_spreadsheet TYPE REF TO zcl_docs_spreadsheet.

  lo_doc = super->new_doc_from_json( ip_json = ip_json ).

  CREATE OBJECT lo_doc_spreadsheet
    EXPORTING
      i_consumer_name = me->consumer_name
      i_user_name     = me->user_name.

  lo_doc_spreadsheet->from_generic_doc( lo_doc ).
  eo_doc = lo_doc_spreadsheet.

endmethod.


method ZIF_DOCS_SPREADSHEET~ADD_WORKSHEET.
endmethod.


method ZIF_DOCS_SPREADSHEET~DELETE_WORKSHEET.
endmethod.


method ZIF_DOCS_SPREADSHEET~GET_WORKSHEET.
endmethod.


method ZIF_DOCS~GET_LIST.

  DATA: lo_json_doc TYPE REF TO zcl_json_document,
        lo_doc      TYPE REF TO zif_docs.

  DATA: lv_json       TYPE string,
        lv_json_feed  TYPE string,
        lv_json_entry TYPE string.

  lv_json = me->oauth->get_spreadsheet_list( ).

  lo_json_doc = zcl_json_document=>create_with_json( lv_json ).
  lv_json_feed = lo_json_doc->get_value( 'feed' ).

  lo_json_doc = zcl_json_document=>create_with_json( lv_json_feed ).
  lv_json_entry = lo_json_doc->get_value( 'entry' ).

  lo_json_doc = zcl_json_document=>create_with_json( lv_json_entry ).

  WHILE lo_json_doc->get_next( ) IS NOT INITIAL.

    lv_json = lo_json_doc->get_json( ).

    lo_doc = me->new_doc_from_json( lv_json ).
    me->zif_docs~doc_list->add( lo_doc ).
  ENDWHILE.

endmethod.


method ZIF_DOCS~UPLOAD.
*CALL METHOD SUPER->ZIF_DOCS~UPLOAD
*    .
  DATA response TYPE ZOAUTH2_API_RESPONSE.
  response = me->oauth->UPLOAD_SPREADSHEET(
               I_DOCUMENT = I_DOCUMENT
               I_TITLE = I_TITLE
               I_SIZE = I_SIZE
   ).


endmethod.
ENDCLASS.
