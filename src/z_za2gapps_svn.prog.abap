*&---------------------------------------------------------------------*
*& Report  Z_ZA2X_SVN
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z_ZA2GAPPS_SVN.

TYPE-POOLS abap.

CONSTANTS cl_svn TYPE seoclsname VALUE 'ZCL_ZAKE_SVN'.
CONSTANTS cl_tortoise_svn TYPE seoclsname VALUE 'ZCL_ZAKE_TORTOISE_SVN'.

DATA package TYPE devclass.
DATA lt_packages TYPE TABLE OF devclass.
DATA zake    TYPE REF TO zake.
DATA objects TYPE scts_tadir.
DATA object  LIKE LINE OF objects.
DATA objtype TYPE string.
DATA objname TYPE string.
DATA nuggetname TYPE string.
DATA comment_str TYPE string.
DATA loclpath_str TYPE string.
DATA svnpath_str TYPE string.
DATA username_str TYPE string.
DATA password_str TYPE string.
DATA class TYPE seoclsname.
DATA files TYPE string_table.
DATA file LIKE LINE OF files.

DATA: ex TYPE REF TO zcx_saplink,
      message TYPE string.

SELECTION-SCREEN BEGIN OF BLOCK a WITH FRAME TITLE a.
PARAMETERS:
  checkout TYPE flag RADIOBUTTON GROUP act,
  update   TYPE flag RADIOBUTTON GROUP act,
  install  TYPE flag RADIOBUTTON GROUP act,
  build    TYPE flag RADIOBUTTON GROUP act DEFAULT 'X',
  checkin  TYPE flag RADIOBUTTON GROUP act.
SELECTION-SCREEN END OF BLOCK a.

SELECTION-SCREEN BEGIN OF BLOCK b WITH FRAME TITLE b.
PARAMETERS:
  svn      TYPE flag RADIOBUTTON GROUP cl,
  tortoise TYPE flag RADIOBUTTON GROUP cl.
SELECTION-SCREEN END OF BLOCK b.

SELECTION-SCREEN BEGIN OF BLOCK c WITH FRAME TITLE c.
PARAMETERS:
  loclpath TYPE char512 DEFAULT 'C:\Users\ivan\ZAKE_SVN\Projects\abap2gapps\trunk' LOWER CASE OBLIGATORY,
  " loclpath TYPE char512 DEFAULT 'C:/Projects/abap2xlsx-dev/' LOWER CASE OBLIGATORY,
  nuggetna TYPE char512 DEFAULT 'C:\Users\ivan\ZAKE_SVN\Projects\abap2gapps\build\nuggs\ABAP2GAPPS_daily.nugg' LOWER CASE OBLIGATORY,
  svnpath  TYPE char512 DEFAULT 'https://code.sdn.sap.com/svn/abap2gapps' LOWER CASE OBLIGATORY,
  revision TYPE i,
  comment  TYPE char512 DEFAULT '' LOWER CASE,
  testrun  TYPE flag    DEFAULT 'X',
  transpor TYPE flag.
SELECTION-SCREEN END OF BLOCK c.

INITIALIZATION.
  a = 'Action'.
  b = 'Version Controll Program'.
  c = 'Parameters'.

START-OF-SELECTION.

* Loop around the Packages which are returned for the Select Options select
  svnpath_str  = svnpath.
  loclpath_str = loclpath.
  nuggetname  = nuggetna.
  TRY.
*      " DDIC Objects
*      " Domain
*      object-object   = 'DOMA'.
*      object-obj_name = ''.
*      APPEND object TO objects.
*      " Data Element
*      object-object   = 'DTEL'.
*      object-obj_name = ''.
*      APPEND object TO objects.
*      " Table Type
*      object-object   = 'TTYP'.
*      object-obj_name = ''.
*      APPEND object TO objects.
*      " Structure
*      object-object   = 'TABL'.
*      object-obj_name = ''.
*      APPEND object TO objects.
*      " Interface
*      object-object   = 'INTF'.
*      object-obj_name = ''.
*      APPEND object TO objects.
*      " Classes
*      object-object   = 'CLAS'.
*      object-obj_name = ''.
*      APPEND object TO objects.
**      " Reports
      object-object   = 'PROG'.
      object-obj_name = 'Z_GAABAP_SETUP_1_API_KEY'.
      APPEND object TO objects.
      object-object   = 'PROG'.
      object-obj_name = 'Z_GAABAP_SETUP_2_REGISTER_USER'.
      APPEND object TO objects.
      object-object   = 'PROG'.
      object-obj_name = 'Z_ZA2GAPPS_SVN'.
      APPEND object TO objects.

      IF svn = 'X'.
        class = cl_svn.
      ELSE.
        class = cl_tortoise_svn.
      ENDIF.

      CREATE OBJECT zake
        TYPE
          (class)
        EXPORTING
          i_svnpath   = svnpath_str
          i_localpath = loclpath_str.

*      CONCATENATE loclpath 'ZA2X/licence.txt' INTO file.
*      APPEND file TO files.
*      CONCATENATE loclpath 'ZA2X/readme.txt' INTO file.
*      APPEND file TO files.
      zake->add_files_to_zip( files ).
      zake->set_package( 'ZABAP2GAPPS' ).

      IF checkin = 'X'.
        zake->set_checkin_objects( objects ).

        zake->create_slinkees( ).

        IF testrun IS INITIAL.
          comment_str = comment.
          zake->checkin( comment_str ).
        ENDIF.
      ELSE.
        IF update = 'X'.
          zake->update( ).
        ELSEIF checkout = 'X'.
          zake->checkout( revision ).
        ELSEIF install = abap_true.
          " Install Slinkees
          zake->install_slinkees_from_lm( testrun ).
          " Activate objects
          IF testrun = abap_false.
            zake->activate_package_objects( ).
          ENDIF.
        ELSEIF build = abap_true.
          " Fill Object Table with Slinkees from Local Machine but do not install
          zake->install_slinkees_from_lm( i_testrun = abap_true ).
          " Change package assignment of objects
          zake->set_package_of_package_objects( ).
          IF transpor = abap_true.
            " Create Transport
            zake->create_transport_request( ).
            " Add all Objects to the Transport
            zake->add_package_objects_to_tr( ).
            " Release transport request
            zake->release_transport_request( ).
            " Add transport to ZIP
            zake->download_transport_to_lm = abap_true.
          ENDIF.
          " For the daily build we don't want to write Slinkee's
          zake->download_slinkees_to_lm = abap_false.
          " And also no Nugged
          zake->download_nugget_to_lm = abap_false.
          " Write only the ZIP-File.
          zake->create_slinkees( nuggetname ).
        ENDIF.
      ENDIF.
    CATCH zcx_saplink INTO ex.
      message = ex->get_text( ).
      IF message IS INITIAL.
        message = ex->get_longtext( ).
      ENDIF.
      WRITE: / 'An Error occured: ', message.
  ENDTRY.
