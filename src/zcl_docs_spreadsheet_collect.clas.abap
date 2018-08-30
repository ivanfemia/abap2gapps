class ZCL_DOCS_SPREADSHEET_COLLECT definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_DOCS_SPREADSHEET_COLLECT
*"* do not include other source files here!!!

  methods CLEAR .
  methods CONSTRUCTOR .
  methods GET
    importing
      !IP_INDEX type I
    returning
      value(EO_SPREADSHEET) type ref to ZCL_DOCS_SPREADSHEET .
  methods GET_ITERATOR
    returning
      value(EO_ITERATOR) type ref to CL_OBJECT_COLLECTION_ITERATOR .
  methods IS_EMPTY
    returning
      value(IS_EMPTY) type FLAG .
  methods SIZE
    returning
      value(EP_SIZE) type I .
protected section.
*"* protected components of class ZCL_DOCS_SPREADSHEET_COLLECT
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_DOCS_SPREADSHEET_COLLECT
*"* do not include other source files here!!!

  data SPREADSHEETS type ref to CL_OBJECT_COLLECTION .

  methods ADD .
  methods REMOVE .
ENDCLASS.



CLASS ZCL_DOCS_SPREADSHEET_COLLECT IMPLEMENTATION.


method ADD.
endmethod.


METHOD clear.
  me->spreadsheets->clear( ).
ENDMETHOD.


METHOD constructor.
  CREATE OBJECT me->spreadsheets.
ENDMETHOD.


method GET.

  eo_spreadsheet ?= me->spreadsheets->if_object_collection~get( ip_index ).

endmethod.


method GET_ITERATOR.

  eo_iterator ?= me->spreadsheets->if_object_collection~get_iterator( ).

endmethod.


METHOD is_empty.

  is_empty = me->spreadsheets->if_object_collection~is_empty( ).

ENDMETHOD.


method REMOVE.
endmethod.


method SIZE.

  ep_size = me->spreadsheets->if_object_collection~size( ).

endmethod.
ENDCLASS.
