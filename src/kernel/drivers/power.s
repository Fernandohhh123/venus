
poweroff:
    mov     ax, 0x2000
    mov     dx, 0x604
    out     dx, ax
ret
