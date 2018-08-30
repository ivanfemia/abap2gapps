class ZCL_DOCS_COLLECTION definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_DOCS_COLLECTION
*"* do not include other source files here!!!

  methods ADD
    importing
      !IO_DOC type ref to ZIF_DOCS .
  methods CLEAR .
  methods CONSTRUCTOR .
  methods GET
    importing
      !IP_INDEX type I
    returning
      value(EO_DOC) type ref to ZIF_DOCS .
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
*"* protected components of class ZCL_DOCS_COLLECTION
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_DOCS_COLLECTION
*"* do not include other source files here!!!

  data DOCS type ref to CL_OBJECT_COLLECTION .

  methods REMOVE .
ENDCLASS.



CLASS ZCL_DOCS_COLLECTION IMPLEMENTATION.


method ADD.
  me->docs->add( io_doc ).
endmethod.


method CLEAR.
  me->docs->clear( ).
endmethod.


method CONSTRUCTOR.
  CREATE OBJECT me->docs.
endmethod.


method GET.

  eo_doc ?= me->docs->if_object_collection~get( ip_index ).

endmethod.


method GET_ITERATOR.

  eo_iterator ?= me->docs->if_object_collection~get_iterator( ).

endmethod.


method IS_EMPTY.

  is_empty = me->docs->if_object_collection~is_empty( ).

endmethod.


method REMOVE.
endmethod.


method SIZE.

  ep_size = me->docs->if_object_collection~size( ).

endmethod.
ENDCLASS.
