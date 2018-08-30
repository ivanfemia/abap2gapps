class ZCX_DOCS_GDOC_ERROR definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  constants HTTP_401 type SOTR_CONC value '0800273352511EE8AAECCB79F3ED3646' ##NO_TEXT.
  data API_RESPONSE type ZOAUTH2_API_RESPONSE .

  methods CONSTRUCTOR
    importing
      !TEXTID like TEXTID optional
      !PREVIOUS like PREVIOUS optional
      !API_RESPONSE type ZOAUTH2_API_RESPONSE optional .
protected section.
private section.
ENDCLASS.



CLASS ZCX_DOCS_GDOC_ERROR IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
TEXTID = TEXTID
PREVIOUS = PREVIOUS
.
me->API_RESPONSE = API_RESPONSE .
  endmethod.
ENDCLASS.
