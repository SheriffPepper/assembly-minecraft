%ifndef __CORE_MODULE_INCLUDE__
%define __CORE_MODULE_INCLUDE__


%define @module.type  __MODULE__
%define @module.name  _%+@module.type%+MODULE_NAME__


%macro __create_module 2
    ; We're closing another module if it's open
    %ifdef __MODULE__
        __unlink_module %1, "Module was terminated by the definition of another Module with a different type!"
    %endif

    %define %[@module.type]  %1
    %define %[@module.name]  %2
%endmacro


%macro __unlink_module 2
    ; Turn the definition into a string
    %defstr %%__TEMP_MODULE__ %[@module.type]
    %if %%__TEMP_MODULE__ != %1
        %warning %2
    %endif
    %undef  %%__TEMP_MODULE__

    %undef _%[@module.type]MODULE_NAME__
    %undef __MODULE__
%endmacro


%imacro end_module 0
    ; We can't close a module if it's not open (or doesn't have a type)
    %ifndef __MODULE__
        %fatal "Module termination outside the module! Did you forget 'module <MODULE_NAME>'?"
    %endif

    ; Clean the module preprocessor variables
    %defstr %%__TEMP_MODULE__ %[@module.type]
    __unlink_module %%__TEMP_MODULE__, "Module was terminated...and it seems that it was not equal to itself... How did you do that?"
    %undef  %%__TEMP_MODULE__
%endmacro


%imacro implement 0
    ; We can't implement a module if no module is open
    %ifndef __MODULE__
        %warning "Can't implement module since no module was given!"
    %else
        implement %[@module.name]
    %endif
%endmacro


%imacro implement 1
    %define __%1_impl__
%endmacro


;
; Defines the label as "external" if the "implementation identifier" wasn't present,
; and as "global" exported one if the "implementation identifier" was present.
;
%macro define 1
    %ifdef __%[@module.name]_impl__
        global %1    ; Global label for implementation code
    %else
        extern %1    ; External label for consumer code
    %endif
%endmacro


%endif; __CORE_MODULE_INCLUDE__
