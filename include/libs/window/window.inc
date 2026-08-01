;
; Cross-platform "window" library interface.
;


;
; Creates Window singleton with given size and title.
;
;   @param width:  u32  Window width
;   @param height: u32  Window height
;   @param title: *str  pointer to the Window null-terminated title
;
;   @return  boolean of whether Window was created (true) or failed (false)
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads, writes
;
extern Window.create
    ;
    ;   Calling convention:
    ; @param width   ecx (u32 integer)
    ; @param height  edx (u32 integer)
    ; @param title   r8  (pointer)
    ;
    ; @return  eax (boolean)
    ;

;
; Destroy the Window.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads
;
extern Window.destroy

;
; Processes all the events sent.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads, writes
;
extern Window.pollEvents

;
; Returns boolean depending on whether Window should close.
;
;   @return  boolean "is Window should close"
;
; @convention  custom (Blanki)
; @features    x64
; @effects     reads
;
extern Window.shouldClose
    ;
    ;   Calling convention:
    ; @return  eax (boolean)
    ;

;
; Swaps buffers.
;
; [NOTE]: Requires the stack to be 16-bytes aligned.
;
; @convention  custom (Blanki)
; @features    x64
; @effects     stack use, reads
;
extern Window.swapBuffers
