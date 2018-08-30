interface ZIF_DOCS
  public .


  data AUTHOR type ZDOCS_AUTHOR .
  data CATEGORY type ZDOCS_CATEGORY .
  data CONTENT type ZDOCS_CONTENT .
  data CONTENT_BINARY type SOLIX_TAB read-only .
  data CONTENT_XSTRING type XSTRING read-only .
  data GDSETAG type ZDOC_GDSETAG .
  data ID type ZDOCS_ID .
  data LINK type ZDOCS_LINK .
  data LINK_ALTERNATE type ZDOCS_LINK .
  data LINK_SELF type ZDOCS_LINK .
  data SRC type ZDOCS_SRC .
  data TITLE type ZDOCS_TITLE .
  data UPDATED type TIMESTAMPL .
  data DOC_LIST type ref to ZCL_DOCS_COLLECTION read-only .

  methods UPLOAD
    importing
      value(I_DOCUMENT) type XSTRING
      value(I_TITLE) type STRING
      value(I_SIZE) type I .
  methods DOWNLOAD .
  methods GET_LIST .
  methods COPY
    importing
      !IP_SOURCE_ID type ZDOCS_ID
      !IP_TARGET_TITLE type ZDOCS_TITLE default 'Copy of'
    returning
      value(EP_TARGET_ID) type ZDOCS_ID .
  methods DELETE
    importing
      !IP_ID type ZDOCS_ID .
  methods RENAME
    importing
      !IP_ID type ZDOCS_ID
      !IP_TITLE type ZDOCS_TITLE .
  methods SET_CONTENTX
    importing
      !IP_CONTENT type XSTRING .
  methods SET_CONTENTB
    importing
      !IP_CONTENT type SOLIX_TAB .
endinterface.
