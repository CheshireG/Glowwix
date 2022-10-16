;主引导程序
;----------------------------------------------------------
%include "boot.inc"
SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax
;-------------------------------------------------------------------
;利用0x06号功能，上卷全部的行，即可实现清屏
;INT 0x10 功能号0x06 上卷窗口
;--------------------------------------------------------------------
;输入：
;AH 功能号 0x06
;AL = 上卷的行数，为0则全部
;BH = 上卷的行属性
;(CL,CH) 窗口左上角
;(DL,DH) 窗口右下角
;读取硬盘初始化
    mov ax,0600h
    mov bx,0700h
    mov cx,0            ;左上角：(0,0)
    mov dx,184fh        ;右上角：(80,25)
    int 10h


;--------------------------------------------------------------------
    mov eax,LOADER_START_SECTOR  ;起始扇区的LBA地址
    mov bx, LOADER_BASE_ADDR     ;写入的地址
    mov cx, 4                    ;待读入的扇区数
    call rd_disk_m_16            ;读取程序的cx扇区

    jmp LOADER_BASE_ADDR

;--------------------------------------------------------------------
;功能：读取硬盘的cx个扇区
rd_disk_m_16:
;--------------------------------------------------------------------
                                ;eax=LBA扇区号
                                ;bx=将数据写入的内存地址
                                ;cx=读入的扇区数
    mov esi,eax                 ;备份eax
    mov di,cx                   ;备份cx
;读写硬盘：
;第一步：设置要读取的扇区数
    mov dx,0x1f2                ;根据配置文件，ata0为PRIMARY通道，
                                ;所以sector count为0x1f2
    mov al,cl
    out dx,al                   ;往端口号中写入读取的扇区数
    mov eax,esi                 ;恢复ax，前面用到al写数据

;第二步：将LBA地址存入0x1f3 ~ 0x1f6
    mov dx,0x1f3                ;LBA地址的7-0位写入端口0x1f3
    out dx,al 

    mov cl,8                    ;LBA地址的15-8位写入端口0x1f4
    shr eax,cl                  ;目的操作数顺序右移CL寄存器指定的位数
    mov dx,0x1f4                ;右移8位，刚好需要的位数存放在al中
    out dx,al                   

    shr eax,cl                  ;LBA地址23-16位写入端口0x1f5
    mov dx,0x1f5
    out dx,al

    shr eax,cl                  ;LBA地址27-24位写入端口0x1f6（device）
    and al,0x0f                 ;0x0f 0000 1111 al的第四位不变，高四位置0
    or  al,0xe0                 ;0xe0 1110 0000 第四位不变，高四位设置为1110
    mov dx,0x1f6                ;1 MBS固定 1 LBA 1 MBS 0 主盘
    out dx,al       

;第三步；向0x1f7端口写入读命令0x20 command
    mov dx,0x1f7
    mov al,0x20
    out dx,al
;第四步：检测硬盘状态
;同一端口，写时表示写入命令字，读时表示读入硬盘状态
.not_ready:
    nop                         ;空操作，相当于sleep一下
    in  al,dx                   ;读的是status寄存器
    and al,0x88                 ;1000 1000 第四位为1：硬盘准备好数据
                                ;第七位为1表示硬盘忙，这里是把其他位置0
    cmp al,0x08                 ;al - 0x08 
    jnz .not_ready              ;结果不为零（或不相等）则转移
                                ;这里需要满足的条件是硬盘不忙而且数据准备好了即：0x08

;第五步：从0x1f0端口读取数据
    mov ax,di                   ;di存储的是读取的扇区数
    mov dx,256                  ;一个扇区512字节，每次读入一个字，需要di*512/2
    mul dx                      ;被乘数为ax，结果高位在dx，低位在ax
    mov cx,ax

    mov dx,0x1f0

.go_on_read:                    ;不断的读取数据
    in ax,dx
    mov [bx],ax
    add bx,2
    loop .go_on_read
    ret



;--------------------------------------------------------------------
;程序的悬停和补齐
;--------------------------------------------------------------------

    times 510 -($-$$) db 0      ;本行减去本section 
    db 0x55,0xaa     