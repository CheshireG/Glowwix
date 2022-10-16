;----------------------内核加载程序------------------------
%include "boot.inc"
SECTION loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR 		;loader在实模式之下的栈指针地址
jmp loader_start                      	    ;跳过GDT的定义	   

    GDT_BASE:           dd 0x00000000          
                        dd 0x00000000 
    
    CODE_DESC:          dd 0x0000FFFF         		   
                        dd DESC_CODE_HIGH4
    
    DATA_STACK_DESC:    dd 0x0000FFFF
                        dd DESC_DATA_HIGH4

    VIDEO_DESC:         dd 0x80000007       ;limit = (0xbffff-0xb8000(段基址))/4k         	
                        dd DESC_VIDEO_HIGH4 ;=0x7, 显存的段基址是0xb8000,boot.inc设置
    GDT_SIZE            equ $ - GDT_BASE    
    GDT_LIMIT       	equ GDT_SIZE - 1   	           
    
    times 60 dq 0                           ;define quad word 代表的是八个字节
    SELECTOR_CODE           equ (0X0001<<3) + TI_GDT + RPL0   
    SELECTOR_DATA	        equ (0X0002<<3) + TI_GDT + RPL0
    SELECTOR_VIDEO          equ (0X0003<<3) + TI_GDT + RPL0
    
    
    gdt_ptr     dw GDT_LIMIT
                dd GDT_BASE
    
    loadermsg db   'loader in real........'                 

;-------------------------打印字符串---------------------------------
;这里是没有用到显存的
;AH=子功能号13H
;BH=页码
;BL=属性(若AL=00H 01H)
;CX=字符串长度
;(DH,DL)=坐标{行、列}
;ES:BP＝字符串地址
;AL＝显示输出方式
;0-字符串中只含显示字符，其显示属性在BL，显示后，光标位置不变
;1-字符串中只含显示字符，其显示属性在BL，显示后，光标位置改变
;2-字符事中含显示字符和显示属性。显示后，光标位置不变
;3-字符串中含显示字符和显示属性。显示后，光标位置改变
;无返回值
loader_start:
    mov sp,LOADER_BASE_ADDR					
    mov bp,loadermsg                                          
    mov cx,22     
    mov ax,cs                                                
    mov es,ax                                               
    mov ax,0x1301                                             
    mov bx,0x001f                                            
    mov dx,0x1800                                            
    int 0x10
    
; --------------------------------- 设置进入保护模式 -----------------------------
; 1 打开A20 gate
; 2 加载gdt
; 3 将cr0的pe位置1
    
    in al,0x92                 
    or al,0000_0010b
    out 0x92,al

    lgdt [gdt_ptr] 
    
    mov eax,cr0                
    or  eax,0x00000001              
    mov cr0,eax

;-------------------------------- 进入保护模式 ---------------------------------------
    jmp dword SELECTOR_CODE:p_mode_start                 ;刷新流水线

[bits 32]
p_mode_start: 
    mov ax,SELECTOR_DATA
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,LOADER_STACK_TOP
    mov ax,SELECTOR_VIDEO
    mov gs,ax
    
    mov byte [gs:160],'P'
    
    jmp $          

;-----------------------记录-------------------------
;1
;第85行，是显存的第80个字符的位置，也就是第二行首字符，因为
;每行是80个字符（共25行），加上属性也就是160个字符，所以这里
;是相对于显存地址的开始来看的，所以这里的段基地址需要设置成
;显存的地址，这里没有属性，默认白底黑字

;2
;刷新流水线，是由于之前的段描述符缓冲寄存器存放的还是20位的
;地址，还是实模式，需要更换寄存器的内容，所以加载选择子，同时
;通过使用jmp指令来清空流水线

;3
;这里将二进制文件写入的硬盘的时候，对于loader.bin，由于其大于
;512字节，所以需要写入两个块，所以命令的count=2而不是1，否则
;就会出现GDT描述符可以正常查看，而PE位却不能改变（没有进入保护
;模式）的情况，