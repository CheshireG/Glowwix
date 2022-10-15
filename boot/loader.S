;------------------------------------------
;内核加载程序
%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR

;输出背景色为绿色，前景色为红色，跳动的字符串“2 LOADER”
    mov byte [gs:0x00],'2'      ;从显存的第0个字节，也就是字符在左上角出现
    mov byte [gs:0x01],0xA4     ;A代表绿色背景闪烁，4表示前景色为红色
                                ;这里使用8位表示字符的属性
                                ;1010 0100 对应 KRGB(背景) IRGB(前景)
    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0xA4

    mov byte [gs:0x04],'L'
    mov byte [gs:0x05],0xA4

    mov byte [gs:0x06],'O'
    mov byte [gs:0x07],0xA4

    mov byte [gs:0x08],'A'
    mov byte [gs:0x09],0xA4

    mov byte [gs:0x0a],'D'
    mov byte [gs:0x0b],0xA4

    mov byte [gs:0x0c],'E'
    mov byte [gs:0x0d],0xA4

    mov byte [gs:0x0e],'R'
    mov byte [gs:0x0f],0xA4


;---------------------------------------------------------
    jmp $                           ;程序悬停