class ZCL_DOCS definition
  public
  create public .

*"* public components of class ZCL_DOCS
*"* do not include other source files here!!!
public section.

  interfaces ZIF_DOCS .

  methods CONSTRUCTOR
    importing
      !I_CONSUMER_NAME type ZOAUTH2_CONSUMER_NAME
      !I_USER_NAME type ZOAUTH2_USER_NAME optional
      !I_PROXY_HOST type STRING optional
      !I_PROXY_SERVICE type STRING optional
      !I_SSL_ID type SSFAPPLSSL optional .
protected section.
*"* protected components of class ZCL_DOCS
*"* do not include other source files here!!!

  data OAUTH type ref to ZCL_DOCS_GDOC .
  data CONSUMER_NAME type ZOAUTH2_CONSUMER_NAME .
  data USER_NAME type ZOAUTH2_USER_NAME .
  data PROXY_HOST type STRING .
  data PROXY_SERVICE type STRING .
  data SSL_ID type SSFAPPLSSL .

  methods NEW_DOC_FROM_JSON
    importing
      !IP_JSON type STRING
    returning
      value(EO_DOC) type ref to ZIF_DOCS .
private section.
*"* private components of class ZCL_DOCS
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_DOCS IMPLEMENTATION.


METHOD constructor.

  me->consumer_name = i_consumer_name.
  me->user_name     = i_user_name.
  me->proxy_host    = i_proxy_host.
  me->proxy_service = i_proxy_service.
  me->ssl_id        = i_ssl_id.

  " creates Oauth object
  CREATE OBJECT me->oauth
    EXPORTING
      i_consumer_name = i_consumer_name
      i_user_name     = i_user_name
      i_proxy_host    = i_proxy_host
      i_proxy_service = i_proxy_service
      i_ssl_id        = i_ssl_id.

  CREATE OBJECT me->zif_docs~doc_list.

ENDMETHOD.


method NEW_DOC_FROM_JSON.

  DATA: lo_json_doc           TYPE REF TO zcl_json_document,
        lo_json_element       TYPE REF TO zcl_json_document,
        lo_doc                TYPE REF TO zif_docs,
        ls_author             TYPE zdocs_author,
        ls_category           TYPE zdocs_category,
        ls_link               TYPE zdocs_link,
        ls_link_alternate     TYPE zdocs_link,
        ls_link_self          TYPE zdocs_link,
        ls_link_temp          TYPE zdocs_link,
        lv_json               TYPE string,
        lv_gdsetag            TYPE string,
        lv_id                 TYPE string,
        lv_updated            TYPE string,
        lv_category           TYPE string,
        lv_category_scheme    TYPE string,
        lv_category_term      TYPE string,
        lv_title              TYPE string,
        lv_content            TYPE string,
        lv_src                TYPE string,
        lv_link               TYPE string,
        lv_link_rel           TYPE string,
        lv_link_type          TYPE string,
        lv_link_href          TYPE string,
        lv_author             TYPE string,
        lv_author_name        TYPE string,
        lv_author_email       TYPE string.


  lo_json_doc = zcl_json_document=>create_with_json( ip_json ).

  " Parse basic data
  lv_gdsetag    = lo_json_doc->get_value( 'gd$etag' ).
  lv_id         = lo_json_doc->get_value( 'id' ).
  lv_updated    = lo_json_doc->get_value( 'updated' ).
  lv_category   = lo_json_doc->get_value( 'category' ).
  lv_title      = lo_json_doc->get_value( 'title' ).
  lv_content    = lo_json_doc->get_value( 'content' ).
  lv_src        = lo_json_doc->get_value( 'src' ).
  lv_link       = lo_json_doc->get_value( 'link' ).
  lv_author     = lo_json_doc->get_value( 'author' ).

  "Parse id
  lo_json_doc = zcl_json_document=>create_with_json( lv_id ).
  lv_id = lo_json_doc->get_value( '$t' ).

  "Parse updated
  lo_json_doc = zcl_json_document=>create_with_json( lv_updated ).
  lv_updated = lo_json_doc->get_value( '$t' ).
  REPLACE ALL OCCURRENCES OF '-' IN lv_updated WITH ''.
  REPLACE ALL OCCURRENCES OF ':' IN lv_updated WITH ''.
  REPLACE ALL OCCURRENCES OF 'Z' IN lv_updated WITH ''.
  REPLACE ALL OCCURRENCES OF 'T' IN lv_updated WITH ''.

  "Parse title
  lo_json_doc = zcl_json_document=>create_with_json( lv_title ).
  lv_title = lo_json_doc->get_value( '$t' ).

  "Parse content
  lo_json_doc = zcl_json_document=>create_with_json( lv_content ).
  lv_content = lo_json_doc->get_value( 'type' ).

  "Parse category
  lo_json_doc = zcl_json_document=>create_with_json( lv_category ).
  WHILE lo_json_doc->get_next( ) IS NOT INITIAL.
    lv_json               = lo_json_doc->get_json( ).
    lo_json_element       = zcl_json_document=>create_with_json( lv_json ).
    lv_category_scheme    = lo_json_element->get_value( 'scheme' ).
    lv_category_term      = lo_json_element->get_value( 'term' ).
    ls_category-scheme  = lv_category_scheme.
    ls_category-term    = lv_category_term.
  ENDWHILE.

  "Parse link
  lo_json_doc = zcl_json_document=>create_with_json( lv_link ).
  WHILE lo_json_doc->get_next( ) IS NOT INITIAL.
    lv_json               = lo_json_doc->get_json( ).
    lo_json_element       = zcl_json_document=>create_with_json( lv_json ).
    lv_link_rel           = lo_json_element->get_value( 'rel' ).
    lv_link_type          = lo_json_element->get_value( 'type' ).
    lv_link_href          = lo_json_element->get_value( 'href' ).
    ls_link_temp-rel   = lv_link_rel.
    ls_link_temp-type  = lv_link_type.
    ls_link_temp-href  = lv_link_href.
    CASE lv_link_rel.
      WHEN 'alternate'.
        ls_link_alternate = ls_link_temp.
      WHEN 'self'.
        ls_link_self      = ls_link_temp.
      WHEN OTHERS.
        ls_link           = ls_link_temp.
    ENDCASE.
    CLEAR ls_link_temp.
  ENDWHILE.

  "Parse author
  lo_json_doc = zcl_json_document=>create_with_json( lv_author ).
  WHILE lo_json_doc->get_next( ) IS NOT INITIAL.
    lv_json               = lo_json_doc->get_json( ).
    lo_json_element       = zcl_json_document=>create_with_json( lv_json ).
    lv_author_name        = lo_json_element->get_value( 'name' ).
    lv_author_email       = lo_json_element->get_value( 'email' ).
    ls_author-name  = lv_author_name.
    ls_author-email = lv_author_email.
  ENDWHILE.

  CREATE OBJECT eo_doc TYPE zcl_docs
    EXPORTING
      i_consumer_name = me->consumer_name
      i_user_name     = me->user_name.

  eo_doc->gdsetag         = lv_gdsetag.
  eo_doc->id              = lv_id.
  eo_doc->updated         = lv_updated.
  eo_doc->category        = ls_category.
  eo_doc->title           = lv_title.
  eo_doc->content         = lv_content.
  eo_doc->src             = lv_src.
  eo_doc->link            = ls_link.
  eo_doc->link_alternate  = ls_link_alternate.
  eo_doc->link_self       = ls_link_self.
  eo_doc->author          = ls_author.

endmethod.


method ZIF_DOCS~COPY.
endmethod.


method ZIF_DOCS~GET_LIST.

*  DATA: lo_json_doc TYPE REF TO zcl_json_document,
*        lo_doc      TYPE REF TO zif_docs.
*
*  DATA: lv_json       TYPE string,
*        lv_json_feed  TYPE string,
*        lv_json_entry TYPE string.
*
*  lv_json = me->oauth->get_spreadsheet_list( ).
*
*  lo_json_doc = zcl_json_document=>create_with_json( lv_json ).
*  lv_json_feed = lo_json_doc->get_value( 'feed' ).
*
*  lo_json_doc = zcl_json_document=>create_with_json( lv_json_feed ).
*  lv_json_entry = lo_json_doc->get_value( 'entry' ).
*
*  lo_json_doc = zcl_json_document=>create_with_json( lv_json_entry ).
*
*  WHILE lo_json_doc->get_next( ) IS NOT INITIAL.
*
*    lv_json = lo_json_doc->get_json( ).
*
*    lo_doc = me->new_doc_from_json( lv_json ).
*    me->zif_docs~doc_list->add( lo_doc ).
*  ENDWHILE.

endmethod.


method ZIF_DOCS~UPLOAD.
endmethod.
ENDCLASS.
