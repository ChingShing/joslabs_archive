
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 03 01 00 00       	call   f0100141 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
f0100047:	8d 5d 14             	lea    0x14(%ebp),%ebx
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010004a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010004d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100051:	8b 45 08             	mov    0x8(%ebp),%eax
f0100054:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100058:	c7 04 24 40 1a 10 f0 	movl   $0xf0101a40,(%esp)
f010005f:	e8 07 09 00 00       	call   f010096b <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 c5 08 00 00       	call   f0100938 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 e2 1a 10 f0 	movl   $0xf0101ae2,(%esp)
f010007a:	e8 ec 08 00 00       	call   f010096b <cprintf>
	va_end(ap);
}
f010007f:	83 c4 14             	add    $0x14,%esp
f0100082:	5b                   	pop    %ebx
f0100083:	5d                   	pop    %ebp
f0100084:	c3                   	ret    

f0100085 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100085:	55                   	push   %ebp
f0100086:	89 e5                	mov    %esp,%ebp
f0100088:	56                   	push   %esi
f0100089:	53                   	push   %ebx
f010008a:	83 ec 10             	sub    $0x10,%esp
f010008d:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100090:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f0100097:	75 3d                	jne    f01000d6 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100099:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010009f:	fa                   	cli    
f01000a0:	fc                   	cld    
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
f01000a1:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01000ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000b2:	c7 04 24 5a 1a 10 f0 	movl   $0xf0101a5a,(%esp)
f01000b9:	e8 ad 08 00 00       	call   f010096b <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 6e 08 00 00       	call   f0100938 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 e2 1a 10 f0 	movl   $0xf0101ae2,(%esp)
f01000d1:	e8 95 08 00 00       	call   f010096b <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 07 07 00 00       	call   f01007e9 <monitor>
f01000e2:	eb f2                	jmp    f01000d6 <_panic+0x51>

f01000e4 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 14             	sub    $0x14,%esp
f01000eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f01000ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f2:	c7 04 24 72 1a 10 f0 	movl   $0xf0101a72,(%esp)
f01000f9:	e8 6d 08 00 00       	call   f010096b <cprintf>
	if (x > 0)
f01000fe:	85 db                	test   %ebx,%ebx
f0100100:	7e 0d                	jle    f010010f <test_backtrace+0x2b>
		test_backtrace(x-1);
f0100102:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100105:	89 04 24             	mov    %eax,(%esp)
f0100108:	e8 d7 ff ff ff       	call   f01000e4 <test_backtrace>
f010010d:	eb 1c                	jmp    f010012b <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010010f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100116:	00 
f0100117:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010011e:	00 
f010011f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100126:	e8 97 05 00 00       	call   f01006c2 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010012b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012f:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100136:	e8 30 08 00 00       	call   f010096b <cprintf>
}
f010013b:	83 c4 14             	add    $0x14,%esp
f010013e:	5b                   	pop    %ebx
f010013f:	5d                   	pop    %ebp
f0100140:	c3                   	ret    

f0100141 <i386_init>:

void
i386_init(void)
{
f0100141:	55                   	push   %ebp
f0100142:	89 e5                	mov    %esp,%ebp
f0100144:	83 ec 18             	sub    $0x18,%esp
	//char chnum1 = 0, chnum2 = 0, ntest[256] = {};

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100147:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f010014c:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100151:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100155:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010015c:	00 
f010015d:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f0100164:	e8 ed 13 00 00       	call   f0101556 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100169:	e8 4c 03 00 00       	call   f01004ba <cons_init>

	int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f010016e:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0100175:	00 
f0100176:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f010017d:	00 
f010017e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100185:	00 
f0100186:	c7 04 24 a9 1a 10 f0 	movl   $0xf0101aa9,(%esp)
f010018d:	e8 d9 07 00 00       	call   f010096b <cprintf>
	// cprintf("chnum1: %d\n", chnum1);
	// cprintf("show me the sign: %+d, %+d\n", 1024, -1024);


	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100192:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100199:	e8 46 ff ff ff       	call   f01000e4 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010019e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01001a5:	e8 3f 06 00 00       	call   f01007e9 <monitor>
f01001aa:	eb f2                	jmp    f010019e <i386_init+0x5d>
f01001ac:	00 00                	add    %al,(%eax)
	...

f01001b0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001b0:	55                   	push   %ebp
f01001b1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001b3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	ec                   	in     (%dx),%al
f01001ba:	ec                   	in     (%dx),%al
f01001bb:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001bc:	5d                   	pop    %ebp
f01001bd:	c3                   	ret    

f01001be <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001be:	55                   	push   %ebp
f01001bf:	89 e5                	mov    %esp,%ebp
f01001c1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c6:	ec                   	in     (%dx),%al
f01001c7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001ce:	f6 c2 01             	test   $0x1,%dl
f01001d1:	74 09                	je     f01001dc <serial_proc_data+0x1e>
f01001d3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001d8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d9:	0f b6 c0             	movzbl %al,%eax
}
f01001dc:	5d                   	pop    %ebp
f01001dd:	c3                   	ret    

f01001de <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001de:	55                   	push   %ebp
f01001df:	89 e5                	mov    %esp,%ebp
f01001e1:	57                   	push   %edi
f01001e2:	56                   	push   %esi
f01001e3:	53                   	push   %ebx
f01001e4:	83 ec 0c             	sub    $0xc,%esp
f01001e7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001e9:	bb 44 25 11 f0       	mov    $0xf0112544,%ebx
f01001ee:	bf 40 23 11 f0       	mov    $0xf0112340,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f3:	eb 1e                	jmp    f0100213 <cons_intr+0x35>
		if (c == 0)
f01001f5:	85 c0                	test   %eax,%eax
f01001f7:	74 1a                	je     f0100213 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001f9:	8b 13                	mov    (%ebx),%edx
f01001fb:	88 04 17             	mov    %al,(%edi,%edx,1)
f01001fe:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100201:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f0100206:	0f 94 c2             	sete   %dl
f0100209:	0f b6 d2             	movzbl %dl,%edx
f010020c:	83 ea 01             	sub    $0x1,%edx
f010020f:	21 d0                	and    %edx,%eax
f0100211:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100213:	ff d6                	call   *%esi
f0100215:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100218:	75 db                	jne    f01001f5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010021a:	83 c4 0c             	add    $0xc,%esp
f010021d:	5b                   	pop    %ebx
f010021e:	5e                   	pop    %esi
f010021f:	5f                   	pop    %edi
f0100220:	5d                   	pop    %ebp
f0100221:	c3                   	ret    

f0100222 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100222:	55                   	push   %ebp
f0100223:	89 e5                	mov    %esp,%ebp
f0100225:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100228:	b8 aa 05 10 f0       	mov    $0xf01005aa,%eax
f010022d:	e8 ac ff ff ff       	call   f01001de <cons_intr>
}
f0100232:	c9                   	leave  
f0100233:	c3                   	ret    

f0100234 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100234:	55                   	push   %ebp
f0100235:	89 e5                	mov    %esp,%ebp
f0100237:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010023a:	83 3d 24 23 11 f0 00 	cmpl   $0x0,0xf0112324
f0100241:	74 0a                	je     f010024d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100243:	b8 be 01 10 f0       	mov    $0xf01001be,%eax
f0100248:	e8 91 ff ff ff       	call   f01001de <cons_intr>
}
f010024d:	c9                   	leave  
f010024e:	c3                   	ret    

f010024f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010024f:	55                   	push   %ebp
f0100250:	89 e5                	mov    %esp,%ebp
f0100252:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100255:	e8 da ff ff ff       	call   f0100234 <serial_intr>
	kbd_intr();
f010025a:	e8 c3 ff ff ff       	call   f0100222 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010025f:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
f0100265:	b8 00 00 00 00       	mov    $0x0,%eax
f010026a:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f0100270:	74 21                	je     f0100293 <cons_getc+0x44>
		c = cons.buf[cons.rpos++];
f0100272:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100279:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010027c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100282:	0f 94 c1             	sete   %cl
f0100285:	0f b6 c9             	movzbl %cl,%ecx
f0100288:	83 e9 01             	sub    $0x1,%ecx
f010028b:	21 ca                	and    %ecx,%edx
f010028d:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f0100293:	c9                   	leave  
f0100294:	c3                   	ret    

f0100295 <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f0100295:	55                   	push   %ebp
f0100296:	89 e5                	mov    %esp,%ebp
f0100298:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010029b:	e8 af ff ff ff       	call   f010024f <cons_getc>
f01002a0:	85 c0                	test   %eax,%eax
f01002a2:	74 f7                	je     f010029b <getchar+0x6>
		/* do nothing */;
	return c;
}
f01002a4:	c9                   	leave  
f01002a5:	c3                   	ret    

f01002a6 <iscons>:

int
iscons(int fdnum)
{
f01002a6:	55                   	push   %ebp
f01002a7:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01002a9:	b8 01 00 00 00       	mov    $0x1,%eax
f01002ae:	5d                   	pop    %ebp
f01002af:	c3                   	ret    

f01002b0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b0:	55                   	push   %ebp
f01002b1:	89 e5                	mov    %esp,%ebp
f01002b3:	57                   	push   %edi
f01002b4:	56                   	push   %esi
f01002b5:	53                   	push   %ebx
f01002b6:	83 ec 2c             	sub    $0x2c,%esp
f01002b9:	89 c7                	mov    %eax,%edi
f01002bb:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002c0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002c1:	a8 20                	test   $0x20,%al
f01002c3:	75 21                	jne    f01002e6 <cons_putc+0x36>
f01002c5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ca:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002cf:	e8 dc fe ff ff       	call   f01001b0 <delay>
f01002d4:	89 f2                	mov    %esi,%edx
f01002d6:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002d7:	a8 20                	test   $0x20,%al
f01002d9:	75 0b                	jne    f01002e6 <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002db:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002de:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01002e4:	75 e9                	jne    f01002cf <cons_putc+0x1f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002e6:	89 fa                	mov    %edi,%edx
f01002e8:	89 f8                	mov    %edi,%eax
f01002ea:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f3:	b2 79                	mov    $0x79,%dl
f01002f5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002f6:	84 c0                	test   %al,%al
f01002f8:	78 21                	js     f010031b <cons_putc+0x6b>
f01002fa:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ff:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100304:	e8 a7 fe ff ff       	call   f01001b0 <delay>
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030c:	84 c0                	test   %al,%al
f010030e:	78 0b                	js     f010031b <cons_putc+0x6b>
f0100310:	83 c3 01             	add    $0x1,%ebx
f0100313:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f0100319:	75 e9                	jne    f0100304 <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031b:	ba 78 03 00 00       	mov    $0x378,%edx
f0100320:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100324:	ee                   	out    %al,(%dx)
f0100325:	b2 7a                	mov    $0x7a,%dl
f0100327:	b8 0d 00 00 00       	mov    $0xd,%eax
f010032c:	ee                   	out    %al,(%dx)
f010032d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100332:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100333:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100339:	75 06                	jne    f0100341 <cons_putc+0x91>
		c |= 0x0700;
f010033b:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	25 ff 00 00 00       	and    $0xff,%eax
f0100348:	83 f8 09             	cmp    $0x9,%eax
f010034b:	0f 84 83 00 00 00    	je     f01003d4 <cons_putc+0x124>
f0100351:	83 f8 09             	cmp    $0x9,%eax
f0100354:	7f 0c                	jg     f0100362 <cons_putc+0xb2>
f0100356:	83 f8 08             	cmp    $0x8,%eax
f0100359:	0f 85 a9 00 00 00    	jne    f0100408 <cons_putc+0x158>
f010035f:	90                   	nop
f0100360:	eb 18                	jmp    f010037a <cons_putc+0xca>
f0100362:	83 f8 0a             	cmp    $0xa,%eax
f0100365:	8d 76 00             	lea    0x0(%esi),%esi
f0100368:	74 40                	je     f01003aa <cons_putc+0xfa>
f010036a:	83 f8 0d             	cmp    $0xd,%eax
f010036d:	8d 76 00             	lea    0x0(%esi),%esi
f0100370:	0f 85 92 00 00 00    	jne    f0100408 <cons_putc+0x158>
f0100376:	66 90                	xchg   %ax,%ax
f0100378:	eb 38                	jmp    f01003b2 <cons_putc+0x102>
	case '\b':
		if (crt_pos > 0) {
f010037a:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f0100381:	66 85 c0             	test   %ax,%ax
f0100384:	0f 84 e8 00 00 00    	je     f0100472 <cons_putc+0x1c2>
			crt_pos--;
f010038a:	83 e8 01             	sub    $0x1,%eax
f010038d:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100393:	0f b7 c0             	movzwl %ax,%eax
f0100396:	66 81 e7 00 ff       	and    $0xff00,%di
f010039b:	83 cf 20             	or     $0x20,%edi
f010039e:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f01003a4:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003a8:	eb 7b                	jmp    f0100425 <cons_putc+0x175>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003aa:	66 83 05 30 23 11 f0 	addw   $0x50,0xf0112330
f01003b1:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b2:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003b9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003bf:	c1 e8 10             	shr    $0x10,%eax
f01003c2:	66 c1 e8 06          	shr    $0x6,%ax
f01003c6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c9:	c1 e0 04             	shl    $0x4,%eax
f01003cc:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
f01003d2:	eb 51                	jmp    f0100425 <cons_putc+0x175>
		break;
	case '\t':
		cons_putc(' ');
f01003d4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d9:	e8 d2 fe ff ff       	call   f01002b0 <cons_putc>
		cons_putc(' ');
f01003de:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e3:	e8 c8 fe ff ff       	call   f01002b0 <cons_putc>
		cons_putc(' ');
f01003e8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ed:	e8 be fe ff ff       	call   f01002b0 <cons_putc>
		cons_putc(' ');
f01003f2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f7:	e8 b4 fe ff ff       	call   f01002b0 <cons_putc>
		cons_putc(' ');
f01003fc:	b8 20 00 00 00       	mov    $0x20,%eax
f0100401:	e8 aa fe ff ff       	call   f01002b0 <cons_putc>
f0100406:	eb 1d                	jmp    f0100425 <cons_putc+0x175>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100408:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f010040f:	0f b7 c8             	movzwl %ax,%ecx
f0100412:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100418:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f010041c:	83 c0 01             	add    $0x1,%eax
f010041f:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100425:	66 81 3d 30 23 11 f0 	cmpw   $0x7cf,0xf0112330
f010042c:	cf 07 
f010042e:	76 42                	jbe    f0100472 <cons_putc+0x1c2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100430:	a1 2c 23 11 f0       	mov    0xf011232c,%eax
f0100435:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010043c:	00 
f010043d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100443:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100447:	89 04 24             	mov    %eax,(%esp)
f010044a:	e8 66 11 00 00       	call   f01015b5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044f:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100455:	b8 80 07 00 00       	mov    $0x780,%eax
f010045a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100460:	83 c0 01             	add    $0x1,%eax
f0100463:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100468:	75 f0                	jne    f010045a <cons_putc+0x1aa>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010046a:	66 83 2d 30 23 11 f0 	subw   $0x50,0xf0112330
f0100471:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100472:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f0100478:	89 cb                	mov    %ecx,%ebx
f010047a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047f:	89 ca                	mov    %ecx,%edx
f0100481:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100482:	0f b7 35 30 23 11 f0 	movzwl 0xf0112330,%esi
f0100489:	83 c1 01             	add    $0x1,%ecx
f010048c:	89 f0                	mov    %esi,%eax
f010048e:	66 c1 e8 08          	shr    $0x8,%ax
f0100492:	89 ca                	mov    %ecx,%edx
f0100494:	ee                   	out    %al,(%dx)
f0100495:	b8 0f 00 00 00       	mov    $0xf,%eax
f010049a:	89 da                	mov    %ebx,%edx
f010049c:	ee                   	out    %al,(%dx)
f010049d:	89 f0                	mov    %esi,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004a2:	83 c4 2c             	add    $0x2c,%esp
f01004a5:	5b                   	pop    %ebx
f01004a6:	5e                   	pop    %esi
f01004a7:	5f                   	pop    %edi
f01004a8:	5d                   	pop    %ebp
f01004a9:	c3                   	ret    

f01004aa <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01004aa:	55                   	push   %ebp
f01004ab:	89 e5                	mov    %esp,%ebp
f01004ad:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01004b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01004b3:	e8 f8 fd ff ff       	call   f01002b0 <cons_putc>
}
f01004b8:	c9                   	leave  
f01004b9:	c3                   	ret    

f01004ba <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ba:	55                   	push   %ebp
f01004bb:	89 e5                	mov    %esp,%ebp
f01004bd:	57                   	push   %edi
f01004be:	56                   	push   %esi
f01004bf:	53                   	push   %ebx
f01004c0:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004c3:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01004c8:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01004cb:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01004d0:	0f b7 00             	movzwl (%eax),%eax
f01004d3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004d7:	74 11                	je     f01004ea <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004d9:	c7 05 28 23 11 f0 b4 	movl   $0x3b4,0xf0112328
f01004e0:	03 00 00 
f01004e3:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01004e8:	eb 16                	jmp    f0100500 <cons_init+0x46>
	} else {
		*cp = was;
f01004ea:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01004f1:	c7 05 28 23 11 f0 d4 	movl   $0x3d4,0xf0112328
f01004f8:	03 00 00 
f01004fb:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100500:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f0100506:	89 cb                	mov    %ecx,%ebx
f0100508:	b8 0e 00 00 00       	mov    $0xe,%eax
f010050d:	89 ca                	mov    %ecx,%edx
f010050f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100510:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100513:	89 ca                	mov    %ecx,%edx
f0100515:	ec                   	in     (%dx),%al
f0100516:	0f b6 f8             	movzbl %al,%edi
f0100519:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010051c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100521:	89 da                	mov    %ebx,%edx
f0100523:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100524:	89 ca                	mov    %ecx,%edx
f0100526:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100527:	89 35 2c 23 11 f0    	mov    %esi,0xf011232c
	crt_pos = pos;
f010052d:	0f b6 c8             	movzbl %al,%ecx
f0100530:	09 cf                	or     %ecx,%edi
f0100532:	66 89 3d 30 23 11 f0 	mov    %di,0xf0112330
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100539:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100543:	89 da                	mov    %ebx,%edx
f0100545:	ee                   	out    %al,(%dx)
f0100546:	b2 fb                	mov    $0xfb,%dl
f0100548:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010054d:	ee                   	out    %al,(%dx)
f010054e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100553:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100558:	89 ca                	mov    %ecx,%edx
f010055a:	ee                   	out    %al,(%dx)
f010055b:	b2 f9                	mov    $0xf9,%dl
f010055d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100562:	ee                   	out    %al,(%dx)
f0100563:	b2 fb                	mov    $0xfb,%dl
f0100565:	b8 03 00 00 00       	mov    $0x3,%eax
f010056a:	ee                   	out    %al,(%dx)
f010056b:	b2 fc                	mov    $0xfc,%dl
f010056d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100572:	ee                   	out    %al,(%dx)
f0100573:	b2 f9                	mov    $0xf9,%dl
f0100575:	b8 01 00 00 00       	mov    $0x1,%eax
f010057a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057b:	b2 fd                	mov    $0xfd,%dl
f010057d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010057e:	3c ff                	cmp    $0xff,%al
f0100580:	0f 95 c0             	setne  %al
f0100583:	0f b6 f0             	movzbl %al,%esi
f0100586:	89 35 24 23 11 f0    	mov    %esi,0xf0112324
f010058c:	89 da                	mov    %ebx,%edx
f010058e:	ec                   	in     (%dx),%al
f010058f:	89 ca                	mov    %ecx,%edx
f0100591:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100592:	85 f6                	test   %esi,%esi
f0100594:	75 0c                	jne    f01005a2 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100596:	c7 04 24 bb 1a 10 f0 	movl   $0xf0101abb,(%esp)
f010059d:	e8 c9 03 00 00       	call   f010096b <cprintf>
}
f01005a2:	83 c4 1c             	add    $0x1c,%esp
f01005a5:	5b                   	pop    %ebx
f01005a6:	5e                   	pop    %esi
f01005a7:	5f                   	pop    %edi
f01005a8:	5d                   	pop    %ebp
f01005a9:	c3                   	ret    

f01005aa <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01005aa:	55                   	push   %ebp
f01005ab:	89 e5                	mov    %esp,%ebp
f01005ad:	53                   	push   %ebx
f01005ae:	83 ec 14             	sub    $0x14,%esp
f01005b1:	ba 64 00 00 00       	mov    $0x64,%edx
f01005b6:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01005b7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01005bc:	a8 01                	test   $0x1,%al
f01005be:	0f 84 d9 00 00 00    	je     f010069d <kbd_proc_data+0xf3>
f01005c4:	b2 60                	mov    $0x60,%dl
f01005c6:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01005c7:	3c e0                	cmp    $0xe0,%al
f01005c9:	75 11                	jne    f01005dc <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01005cb:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
f01005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005d7:	e9 c1 00 00 00       	jmp    f010069d <kbd_proc_data+0xf3>
	} else if (data & 0x80) {
f01005dc:	84 c0                	test   %al,%al
f01005de:	79 32                	jns    f0100612 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01005e0:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f01005e6:	f6 c2 40             	test   $0x40,%dl
f01005e9:	75 03                	jne    f01005ee <kbd_proc_data+0x44>
f01005eb:	83 e0 7f             	and    $0x7f,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01005ee:	0f b6 c0             	movzbl %al,%eax
f01005f1:	0f b6 80 00 1b 10 f0 	movzbl -0xfefe500(%eax),%eax
f01005f8:	83 c8 40             	or     $0x40,%eax
f01005fb:	0f b6 c0             	movzbl %al,%eax
f01005fe:	f7 d0                	not    %eax
f0100600:	21 c2                	and    %eax,%edx
f0100602:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
f0100608:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f010060d:	e9 8b 00 00 00       	jmp    f010069d <kbd_proc_data+0xf3>
	} else if (shift & E0ESC) {
f0100612:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f0100618:	f6 c2 40             	test   $0x40,%dl
f010061b:	74 0c                	je     f0100629 <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010061d:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100620:	83 e2 bf             	and    $0xffffffbf,%edx
f0100623:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
	}

	shift |= shiftcode[data];
f0100629:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010062c:	0f b6 90 00 1b 10 f0 	movzbl -0xfefe500(%eax),%edx
f0100633:	0b 15 20 23 11 f0    	or     0xf0112320,%edx
f0100639:	0f b6 88 00 1c 10 f0 	movzbl -0xfefe400(%eax),%ecx
f0100640:	31 ca                	xor    %ecx,%edx
f0100642:	89 15 20 23 11 f0    	mov    %edx,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100648:	89 d1                	mov    %edx,%ecx
f010064a:	83 e1 03             	and    $0x3,%ecx
f010064d:	8b 0c 8d 00 1d 10 f0 	mov    -0xfefe300(,%ecx,4),%ecx
f0100654:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f0100658:	f6 c2 08             	test   $0x8,%dl
f010065b:	74 1a                	je     f0100677 <kbd_proc_data+0xcd>
		if ('a' <= c && c <= 'z')
f010065d:	89 d9                	mov    %ebx,%ecx
f010065f:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100662:	83 f8 19             	cmp    $0x19,%eax
f0100665:	77 05                	ja     f010066c <kbd_proc_data+0xc2>
			c += 'A' - 'a';
f0100667:	83 eb 20             	sub    $0x20,%ebx
f010066a:	eb 0b                	jmp    f0100677 <kbd_proc_data+0xcd>
		else if ('A' <= c && c <= 'Z')
f010066c:	83 e9 41             	sub    $0x41,%ecx
f010066f:	83 f9 19             	cmp    $0x19,%ecx
f0100672:	77 03                	ja     f0100677 <kbd_proc_data+0xcd>
			c += 'a' - 'A';
f0100674:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100677:	f7 d2                	not    %edx
f0100679:	f6 c2 06             	test   $0x6,%dl
f010067c:	75 1f                	jne    f010069d <kbd_proc_data+0xf3>
f010067e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100684:	75 17                	jne    f010069d <kbd_proc_data+0xf3>
		cprintf("Rebooting!\n");
f0100686:	c7 04 24 d8 1a 10 f0 	movl   $0xf0101ad8,(%esp)
f010068d:	e8 d9 02 00 00       	call   f010096b <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100692:	ba 92 00 00 00       	mov    $0x92,%edx
f0100697:	b8 03 00 00 00       	mov    $0x3,%eax
f010069c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010069d:	89 d8                	mov    %ebx,%eax
f010069f:	83 c4 14             	add    $0x14,%esp
f01006a2:	5b                   	pop    %ebx
f01006a3:	5d                   	pop    %ebp
f01006a4:	c3                   	ret    
	...

f01006b0 <start_overflow>:
    cprintf("Overflow success\n");
}

void
start_overflow(void)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp

	// Your code here.
    


}
f01006b3:	5d                   	pop    %ebp
f01006b4:	c3                   	ret    

f01006b5 <overflow_me>:

void
overflow_me(void)
{
f01006b5:	55                   	push   %ebp
f01006b6:	89 e5                	mov    %esp,%ebp
        start_overflow();
}
f01006b8:	5d                   	pop    %ebp
f01006b9:	c3                   	ret    

f01006ba <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01006ba:	55                   	push   %ebp
f01006bb:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01006bd:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01006c0:	5d                   	pop    %ebp
f01006c1:	c3                   	ret    

f01006c2 <mon_backtrace>:
        start_overflow();
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006c2:	55                   	push   %ebp
f01006c3:	89 e5                	mov    %esp,%ebp
f01006c5:	83 ec 18             	sub    $0x18,%esp
	// Your code here.
    overflow_me();
    cprintf("Backtrace success\n");
f01006c8:	c7 04 24 10 1d 10 f0 	movl   $0xf0101d10,(%esp)
f01006cf:	e8 97 02 00 00       	call   f010096b <cprintf>
	return 0;
}
f01006d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d9:	c9                   	leave  
f01006da:	c3                   	ret    

f01006db <do_overflow>:
    return pretaddr;
}

void
do_overflow(void)
{
f01006db:	55                   	push   %ebp
f01006dc:	89 e5                	mov    %esp,%ebp
f01006de:	83 ec 18             	sub    $0x18,%esp
    cprintf("Overflow success\n");
f01006e1:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006e8:	e8 7e 02 00 00       	call   f010096b <cprintf>
}
f01006ed:	c9                   	leave  
f01006ee:	c3                   	ret    

f01006ef <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006ef:	55                   	push   %ebp
f01006f0:	89 e5                	mov    %esp,%ebp
f01006f2:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f5:	c7 04 24 35 1d 10 f0 	movl   $0xf0101d35,(%esp)
f01006fc:	e8 6a 02 00 00       	call   f010096b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100701:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100708:	00 
f0100709:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100710:	f0 
f0100711:	c7 04 24 c0 1d 10 f0 	movl   $0xf0101dc0,(%esp)
f0100718:	e8 4e 02 00 00       	call   f010096b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010071d:	c7 44 24 08 25 1a 10 	movl   $0x101a25,0x8(%esp)
f0100724:	00 
f0100725:	c7 44 24 04 25 1a 10 	movl   $0xf0101a25,0x4(%esp)
f010072c:	f0 
f010072d:	c7 04 24 e4 1d 10 f0 	movl   $0xf0101de4,(%esp)
f0100734:	e8 32 02 00 00       	call   f010096b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100739:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100740:	00 
f0100741:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100748:	f0 
f0100749:	c7 04 24 08 1e 10 f0 	movl   $0xf0101e08,(%esp)
f0100750:	e8 16 02 00 00       	call   f010096b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100755:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010075c:	00 
f010075d:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100764:	f0 
f0100765:	c7 04 24 2c 1e 10 f0 	movl   $0xf0101e2c,(%esp)
f010076c:	e8 fa 01 00 00       	call   f010096b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100771:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100776:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f010077b:	89 c2                	mov    %eax,%edx
f010077d:	c1 fa 1f             	sar    $0x1f,%edx
f0100780:	c1 ea 16             	shr    $0x16,%edx
f0100783:	8d 04 02             	lea    (%edx,%eax,1),%eax
f0100786:	c1 f8 0a             	sar    $0xa,%eax
f0100789:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078d:	c7 04 24 50 1e 10 f0 	movl   $0xf0101e50,(%esp)
f0100794:	e8 d2 01 00 00       	call   f010096b <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f0100799:	b8 00 00 00 00       	mov    $0x0,%eax
f010079e:	c9                   	leave  
f010079f:	c3                   	ret    

f01007a0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007a0:	55                   	push   %ebp
f01007a1:	89 e5                	mov    %esp,%ebp
f01007a3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a6:	a1 f4 1e 10 f0       	mov    0xf0101ef4,%eax
f01007ab:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007af:	a1 f0 1e 10 f0       	mov    0xf0101ef0,%eax
f01007b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b8:	c7 04 24 4e 1d 10 f0 	movl   $0xf0101d4e,(%esp)
f01007bf:	e8 a7 01 00 00       	call   f010096b <cprintf>
f01007c4:	a1 00 1f 10 f0       	mov    0xf0101f00,%eax
f01007c9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007cd:	a1 fc 1e 10 f0       	mov    0xf0101efc,%eax
f01007d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d6:	c7 04 24 4e 1d 10 f0 	movl   $0xf0101d4e,(%esp)
f01007dd:	e8 89 01 00 00       	call   f010096b <cprintf>
	return 0;
}
f01007e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e7:	c9                   	leave  
f01007e8:	c3                   	ret    

f01007e9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e9:	55                   	push   %ebp
f01007ea:	89 e5                	mov    %esp,%ebp
f01007ec:	57                   	push   %edi
f01007ed:	56                   	push   %esi
f01007ee:	53                   	push   %ebx
f01007ef:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007f2:	c7 04 24 7c 1e 10 f0 	movl   $0xf0101e7c,(%esp)
f01007f9:	e8 6d 01 00 00       	call   f010096b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007fe:	c7 04 24 a0 1e 10 f0 	movl   $0xf0101ea0,(%esp)
f0100805:	e8 61 01 00 00       	call   f010096b <cprintf>

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010080a:	bf f0 1e 10 f0       	mov    $0xf0101ef0,%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f010080f:	c7 04 24 57 1d 10 f0 	movl   $0xf0101d57,(%esp)
f0100816:	e8 b5 0a 00 00       	call   f01012d0 <readline>
f010081b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010081d:	85 c0                	test   %eax,%eax
f010081f:	74 ee                	je     f010080f <monitor+0x26>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100821:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f0100828:	be 00 00 00 00       	mov    $0x0,%esi
f010082d:	eb 06                	jmp    f0100835 <monitor+0x4c>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010082f:	c6 03 00             	movb   $0x0,(%ebx)
f0100832:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100835:	0f b6 03             	movzbl (%ebx),%eax
f0100838:	84 c0                	test   %al,%al
f010083a:	74 6f                	je     f01008ab <monitor+0xc2>
f010083c:	0f be c0             	movsbl %al,%eax
f010083f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100843:	c7 04 24 5b 1d 10 f0 	movl   $0xf0101d5b,(%esp)
f010084a:	e8 af 0c 00 00       	call   f01014fe <strchr>
f010084f:	85 c0                	test   %eax,%eax
f0100851:	75 dc                	jne    f010082f <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100853:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100856:	74 53                	je     f01008ab <monitor+0xc2>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100858:	83 fe 0f             	cmp    $0xf,%esi
f010085b:	90                   	nop
f010085c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100860:	75 16                	jne    f0100878 <monitor+0x8f>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100862:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100869:	00 
f010086a:	c7 04 24 60 1d 10 f0 	movl   $0xf0101d60,(%esp)
f0100871:	e8 f5 00 00 00       	call   f010096b <cprintf>
f0100876:	eb 97                	jmp    f010080f <monitor+0x26>
			return 0;
		}
		argv[argc++] = buf;
f0100878:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010087c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010087f:	0f b6 03             	movzbl (%ebx),%eax
f0100882:	84 c0                	test   %al,%al
f0100884:	75 0c                	jne    f0100892 <monitor+0xa9>
f0100886:	eb ad                	jmp    f0100835 <monitor+0x4c>
			buf++;
f0100888:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010088b:	0f b6 03             	movzbl (%ebx),%eax
f010088e:	84 c0                	test   %al,%al
f0100890:	74 a3                	je     f0100835 <monitor+0x4c>
f0100892:	0f be c0             	movsbl %al,%eax
f0100895:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100899:	c7 04 24 5b 1d 10 f0 	movl   $0xf0101d5b,(%esp)
f01008a0:	e8 59 0c 00 00       	call   f01014fe <strchr>
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	74 df                	je     f0100888 <monitor+0x9f>
f01008a9:	eb 8a                	jmp    f0100835 <monitor+0x4c>
			buf++;
	}
	argv[argc] = 0;
f01008ab:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b3:	85 f6                	test   %esi,%esi
f01008b5:	0f 84 54 ff ff ff    	je     f010080f <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008bb:	8b 07                	mov    (%edi),%eax
f01008bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008c4:	89 04 24             	mov    %eax,(%esp)
f01008c7:	e8 bd 0b 00 00       	call   f0101489 <strcmp>
f01008cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01008d1:	85 c0                	test   %eax,%eax
f01008d3:	74 1d                	je     f01008f2 <monitor+0x109>
f01008d5:	a1 fc 1e 10 f0       	mov    0xf0101efc,%eax
f01008da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008de:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008e1:	89 04 24             	mov    %eax,(%esp)
f01008e4:	e8 a0 0b 00 00       	call   f0101489 <strcmp>
f01008e9:	85 c0                	test   %eax,%eax
f01008eb:	75 28                	jne    f0100915 <monitor+0x12c>
f01008ed:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f01008f2:	6b d2 0c             	imul   $0xc,%edx,%edx
f01008f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01008f8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008fc:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008ff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100903:	89 34 24             	mov    %esi,(%esp)
f0100906:	ff 92 f8 1e 10 f0    	call   *-0xfefe108(%edx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010090c:	85 c0                	test   %eax,%eax
f010090e:	78 1d                	js     f010092d <monitor+0x144>
f0100910:	e9 fa fe ff ff       	jmp    f010080f <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100915:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100918:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091c:	c7 04 24 7d 1d 10 f0 	movl   $0xf0101d7d,(%esp)
f0100923:	e8 43 00 00 00       	call   f010096b <cprintf>
f0100928:	e9 e2 fe ff ff       	jmp    f010080f <monitor+0x26>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010092d:	83 c4 5c             	add    $0x5c,%esp
f0100930:	5b                   	pop    %ebx
f0100931:	5e                   	pop    %esi
f0100932:	5f                   	pop    %edi
f0100933:	5d                   	pop    %ebp
f0100934:	c3                   	ret    
f0100935:	00 00                	add    %al,(%eax)
	...

f0100938 <vcprintf>:
    (*cnt)++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010093e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100945:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100948:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010094c:	8b 45 08             	mov    0x8(%ebp),%eax
f010094f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100953:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100956:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095a:	c7 04 24 85 09 10 f0 	movl   $0xf0100985,(%esp)
f0100961:	e8 97 04 00 00       	call   f0100dfd <vprintfmt>
	return cnt;
}
f0100966:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100969:	c9                   	leave  
f010096a:	c3                   	ret    

f010096b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010096b:	55                   	push   %ebp
f010096c:	89 e5                	mov    %esp,%ebp
f010096e:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100971:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100974:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100978:	8b 45 08             	mov    0x8(%ebp),%eax
f010097b:	89 04 24             	mov    %eax,(%esp)
f010097e:	e8 b5 ff ff ff       	call   f0100938 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100983:	c9                   	leave  
f0100984:	c3                   	ret    

f0100985 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100985:	55                   	push   %ebp
f0100986:	89 e5                	mov    %esp,%ebp
f0100988:	53                   	push   %ebx
f0100989:	83 ec 14             	sub    $0x14,%esp
f010098c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f010098f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100992:	89 04 24             	mov    %eax,(%esp)
f0100995:	e8 10 fb ff ff       	call   f01004aa <cputchar>
    (*cnt)++;
f010099a:	83 03 01             	addl   $0x1,(%ebx)
}
f010099d:	83 c4 14             	add    $0x14,%esp
f01009a0:	5b                   	pop    %ebx
f01009a1:	5d                   	pop    %ebp
f01009a2:	c3                   	ret    
	...

f01009b0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009b0:	55                   	push   %ebp
f01009b1:	89 e5                	mov    %esp,%ebp
f01009b3:	57                   	push   %edi
f01009b4:	56                   	push   %esi
f01009b5:	53                   	push   %ebx
f01009b6:	83 ec 14             	sub    $0x14,%esp
f01009b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009bc:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009bf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009c2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009c5:	8b 1a                	mov    (%edx),%ebx
f01009c7:	8b 01                	mov    (%ecx),%eax
f01009c9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f01009cc:	39 c3                	cmp    %eax,%ebx
f01009ce:	0f 8f 9c 00 00 00    	jg     f0100a70 <stab_binsearch+0xc0>
f01009d4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f01009db:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009de:	01 d8                	add    %ebx,%eax
f01009e0:	89 c7                	mov    %eax,%edi
f01009e2:	c1 ef 1f             	shr    $0x1f,%edi
f01009e5:	01 c7                	add    %eax,%edi
f01009e7:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e9:	39 df                	cmp    %ebx,%edi
f01009eb:	7c 33                	jl     f0100a20 <stab_binsearch+0x70>
f01009ed:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01009f0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01009f3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f01009f8:	39 f0                	cmp    %esi,%eax
f01009fa:	0f 84 bc 00 00 00    	je     f0100abc <stab_binsearch+0x10c>
f0100a00:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f0100a04:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f0100a08:	89 f8                	mov    %edi,%eax
			m--;
f0100a0a:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a0d:	39 d8                	cmp    %ebx,%eax
f0100a0f:	7c 0f                	jl     f0100a20 <stab_binsearch+0x70>
f0100a11:	0f b6 0a             	movzbl (%edx),%ecx
f0100a14:	83 ea 0c             	sub    $0xc,%edx
f0100a17:	39 f1                	cmp    %esi,%ecx
f0100a19:	75 ef                	jne    f0100a0a <stab_binsearch+0x5a>
f0100a1b:	e9 9e 00 00 00       	jmp    f0100abe <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a20:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100a23:	eb 3c                	jmp    f0100a61 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a25:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a28:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100a2a:	8d 5f 01             	lea    0x1(%edi),%ebx
f0100a2d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100a34:	eb 2b                	jmp    f0100a61 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f0100a36:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a39:	76 14                	jbe    f0100a4f <stab_binsearch+0x9f>
			*region_right = m - 1;
f0100a3b:	83 e8 01             	sub    $0x1,%eax
f0100a3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a41:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a44:	89 02                	mov    %eax,(%edx)
f0100a46:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100a4d:	eb 12                	jmp    f0100a61 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a4f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a52:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100a54:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a58:	89 c3                	mov    %eax,%ebx
f0100a5a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a61:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100a64:	0f 8d 71 ff ff ff    	jge    f01009db <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a6a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100a6e:	75 0f                	jne    f0100a7f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100a70:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a73:	8b 03                	mov    (%ebx),%eax
f0100a75:	83 e8 01             	sub    $0x1,%eax
f0100a78:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a7b:	89 02                	mov    %eax,(%edx)
f0100a7d:	eb 57                	jmp    f0100ad6 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100a82:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a84:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a87:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a89:	39 c1                	cmp    %eax,%ecx
f0100a8b:	7d 28                	jge    f0100ab5 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a8d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a90:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100a93:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100a98:	39 f2                	cmp    %esi,%edx
f0100a9a:	74 19                	je     f0100ab5 <stab_binsearch+0x105>
f0100a9c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100aa0:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100aa4:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa7:	39 c1                	cmp    %eax,%ecx
f0100aa9:	7d 0a                	jge    f0100ab5 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100aab:	0f b6 1a             	movzbl (%edx),%ebx
f0100aae:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab1:	39 f3                	cmp    %esi,%ebx
f0100ab3:	75 ef                	jne    f0100aa4 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ab5:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ab8:	89 02                	mov    %eax,(%edx)
f0100aba:	eb 1a                	jmp    f0100ad6 <stab_binsearch+0x126>
	}
}
f0100abc:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100abe:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ac1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100ac4:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100ac8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100acb:	0f 82 54 ff ff ff    	jb     f0100a25 <stab_binsearch+0x75>
f0100ad1:	e9 60 ff ff ff       	jmp    f0100a36 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100ad6:	83 c4 14             	add    $0x14,%esp
f0100ad9:	5b                   	pop    %ebx
f0100ada:	5e                   	pop    %esi
f0100adb:	5f                   	pop    %edi
f0100adc:	5d                   	pop    %ebp
f0100add:	c3                   	ret    

f0100ade <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ade:	55                   	push   %ebp
f0100adf:	89 e5                	mov    %esp,%ebp
f0100ae1:	83 ec 28             	sub    $0x28,%esp
f0100ae4:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100ae7:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100aea:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100af0:	c7 03 08 1f 10 f0    	movl   $0xf0101f08,(%ebx)
	info->eip_line = 0;
f0100af6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100afd:	c7 43 08 08 1f 10 f0 	movl   $0xf0101f08,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b04:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b0b:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b0e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b15:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b1b:	76 12                	jbe    f0100b2f <debuginfo_eip+0x51>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b1d:	b8 02 77 10 f0       	mov    $0xf0107702,%eax
f0100b22:	3d b1 5c 10 f0       	cmp    $0xf0105cb1,%eax
f0100b27:	0f 86 53 01 00 00    	jbe    f0100c80 <debuginfo_eip+0x1a2>
f0100b2d:	eb 1c                	jmp    f0100b4b <debuginfo_eip+0x6d>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b2f:	c7 44 24 08 12 1f 10 	movl   $0xf0101f12,0x8(%esp)
f0100b36:	f0 
f0100b37:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b3e:	00 
f0100b3f:	c7 04 24 1f 1f 10 f0 	movl   $0xf0101f1f,(%esp)
f0100b46:	e8 3a f5 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b4b:	80 3d 01 77 10 f0 00 	cmpb   $0x0,0xf0107701
f0100b52:	0f 85 28 01 00 00    	jne    f0100c80 <debuginfo_eip+0x1a2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b58:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b5f:	b8 b0 5c 10 f0       	mov    $0xf0105cb0,%eax
f0100b64:	2d 40 21 10 f0       	sub    $0xf0102140,%eax
f0100b69:	c1 f8 02             	sar    $0x2,%eax
f0100b6c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b72:	83 e8 01             	sub    $0x1,%eax
f0100b75:	89 45 f0             	mov    %eax,-0x10(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b78:	8d 4d f0             	lea    -0x10(%ebp),%ecx
f0100b7b:	8d 55 f4             	lea    -0xc(%ebp),%edx
f0100b7e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b82:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b89:	b8 40 21 10 f0       	mov    $0xf0102140,%eax
f0100b8e:	e8 1d fe ff ff       	call   f01009b0 <stab_binsearch>
	if (lfile == 0)
f0100b93:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b96:	85 c0                	test   %eax,%eax
f0100b98:	0f 84 e2 00 00 00    	je     f0100c80 <debuginfo_eip+0x1a2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b9e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	rfun = rfile;
f0100ba1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ba4:	89 45 e8             	mov    %eax,-0x18(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ba7:	8d 4d e8             	lea    -0x18(%ebp),%ecx
f0100baa:	8d 55 ec             	lea    -0x14(%ebp),%edx
f0100bad:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bb1:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bb8:	b8 40 21 10 f0       	mov    $0xf0102140,%eax
f0100bbd:	e8 ee fd ff ff       	call   f01009b0 <stab_binsearch>

	if (lfun <= rfun) {
f0100bc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100bc5:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100bc8:	7f 31                	jg     f0100bfb <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bca:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100bcd:	8b 80 40 21 10 f0    	mov    -0xfefdec0(%eax),%eax
f0100bd3:	ba 02 77 10 f0       	mov    $0xf0107702,%edx
f0100bd8:	81 ea b1 5c 10 f0    	sub    $0xf0105cb1,%edx
f0100bde:	39 d0                	cmp    %edx,%eax
f0100be0:	73 08                	jae    f0100bea <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100be2:	05 b1 5c 10 f0       	add    $0xf0105cb1,%eax
f0100be7:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bea:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100bed:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100bf0:	8b 80 48 21 10 f0    	mov    -0xfefdeb8(%eax),%eax
f0100bf6:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bf9:	eb 06                	jmp    f0100c01 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bfb:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bfe:	8b 75 f4             	mov    -0xc(%ebp),%esi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c01:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c08:	00 
f0100c09:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c0c:	89 04 24             	mov    %eax,(%esp)
f0100c0f:	e8 17 09 00 00       	call   f010152b <strfind>
f0100c14:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c17:	89 43 0c             	mov    %eax,0xc(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100c1a:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100c1d:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100c20:	05 48 21 10 f0       	add    $0xf0102148,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c25:	eb 06                	jmp    f0100c2d <debuginfo_eip+0x14f>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c27:	83 ee 01             	sub    $0x1,%esi
f0100c2a:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c2d:	39 ce                	cmp    %ecx,%esi
f0100c2f:	7c 20                	jl     f0100c51 <debuginfo_eip+0x173>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c31:	0f b6 50 fc          	movzbl -0x4(%eax),%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c35:	80 fa 84             	cmp    $0x84,%dl
f0100c38:	74 5c                	je     f0100c96 <debuginfo_eip+0x1b8>
f0100c3a:	80 fa 64             	cmp    $0x64,%dl
f0100c3d:	75 e8                	jne    f0100c27 <debuginfo_eip+0x149>
f0100c3f:	83 38 00             	cmpl   $0x0,(%eax)
f0100c42:	74 e3                	je     f0100c27 <debuginfo_eip+0x149>
f0100c44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100c48:	eb 4c                	jmp    f0100c96 <debuginfo_eip+0x1b8>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c4a:	05 b1 5c 10 f0       	add    $0xf0105cb1,%eax
f0100c4f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c51:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100c54:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100c57:	7d 2e                	jge    f0100c87 <debuginfo_eip+0x1a9>
		for (lline = lfun + 1;
f0100c59:	83 c0 01             	add    $0x1,%eax
f0100c5c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c5f:	81 c2 44 21 10 f0    	add    $0xf0102144,%edx
f0100c65:	eb 07                	jmp    f0100c6e <debuginfo_eip+0x190>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c67:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c6b:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c6e:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100c71:	7d 14                	jge    f0100c87 <debuginfo_eip+0x1a9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c73:	0f b6 0a             	movzbl (%edx),%ecx
f0100c76:	83 c2 0c             	add    $0xc,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c79:	80 f9 a0             	cmp    $0xa0,%cl
f0100c7c:	74 e9                	je     f0100c67 <debuginfo_eip+0x189>
f0100c7e:	eb 07                	jmp    f0100c87 <debuginfo_eip+0x1a9>
f0100c80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c85:	eb 05                	jmp    f0100c8c <debuginfo_eip+0x1ae>
f0100c87:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100c8c:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100c8f:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100c92:	89 ec                	mov    %ebp,%esp
f0100c94:	5d                   	pop    %ebp
f0100c95:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c96:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c99:	8b 86 40 21 10 f0    	mov    -0xfefdec0(%esi),%eax
f0100c9f:	ba 02 77 10 f0       	mov    $0xf0107702,%edx
f0100ca4:	81 ea b1 5c 10 f0    	sub    $0xf0105cb1,%edx
f0100caa:	39 d0                	cmp    %edx,%eax
f0100cac:	72 9c                	jb     f0100c4a <debuginfo_eip+0x16c>
f0100cae:	eb a1                	jmp    f0100c51 <debuginfo_eip+0x173>

f0100cb0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cb0:	55                   	push   %ebp
f0100cb1:	89 e5                	mov    %esp,%ebp
f0100cb3:	57                   	push   %edi
f0100cb4:	56                   	push   %esi
f0100cb5:	53                   	push   %ebx
f0100cb6:	83 ec 4c             	sub    $0x4c,%esp
f0100cb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cbc:	89 d6                	mov    %edx,%esi
f0100cbe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cc4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cc7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100cca:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ccd:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100cd0:	8b 7d 18             	mov    0x18(%ebp),%edi
	// you can add helper function if needed.
	// your code here:


	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cd3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100cd6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cdb:	39 d1                	cmp    %edx,%ecx
f0100cdd:	72 15                	jb     f0100cf4 <printnum+0x44>
f0100cdf:	77 07                	ja     f0100ce8 <printnum+0x38>
f0100ce1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ce4:	39 d0                	cmp    %edx,%eax
f0100ce6:	76 0c                	jbe    f0100cf4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ce8:	83 eb 01             	sub    $0x1,%ebx
f0100ceb:	85 db                	test   %ebx,%ebx
f0100ced:	8d 76 00             	lea    0x0(%esi),%esi
f0100cf0:	7f 61                	jg     f0100d53 <printnum+0xa3>
f0100cf2:	eb 70                	jmp    f0100d64 <printnum+0xb4>
	// your code here:


	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cf4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100cf8:	83 eb 01             	sub    $0x1,%ebx
f0100cfb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cff:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d03:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100d07:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100d0b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100d0e:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100d11:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d14:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100d18:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d1f:	00 
f0100d20:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d23:	89 04 24             	mov    %eax,(%esp)
f0100d26:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100d29:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d2d:	e8 8e 0a 00 00       	call   f01017c0 <__udivdi3>
f0100d32:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100d35:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d38:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d3c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d40:	89 04 24             	mov    %eax,(%esp)
f0100d43:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d47:	89 f2                	mov    %esi,%edx
f0100d49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d4c:	e8 5f ff ff ff       	call   f0100cb0 <printnum>
f0100d51:	eb 11                	jmp    f0100d64 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d53:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d57:	89 3c 24             	mov    %edi,(%esp)
f0100d5a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d5d:	83 eb 01             	sub    $0x1,%ebx
f0100d60:	85 db                	test   %ebx,%ebx
f0100d62:	7f ef                	jg     f0100d53 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d64:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d68:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100d6c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d6f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d73:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d7a:	00 
f0100d7b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d7e:	89 14 24             	mov    %edx,(%esp)
f0100d81:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d84:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100d88:	e8 63 0b 00 00       	call   f01018f0 <__umoddi3>
f0100d8d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d91:	0f be 80 2d 1f 10 f0 	movsbl -0xfefe0d3(%eax),%eax
f0100d98:	89 04 24             	mov    %eax,(%esp)
f0100d9b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d9e:	83 c4 4c             	add    $0x4c,%esp
f0100da1:	5b                   	pop    %ebx
f0100da2:	5e                   	pop    %esi
f0100da3:	5f                   	pop    %edi
f0100da4:	5d                   	pop    %ebp
f0100da5:	c3                   	ret    

f0100da6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100da6:	55                   	push   %ebp
f0100da7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100da9:	83 fa 01             	cmp    $0x1,%edx
f0100dac:	7e 0e                	jle    f0100dbc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100dae:	8b 10                	mov    (%eax),%edx
f0100db0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100db3:	89 08                	mov    %ecx,(%eax)
f0100db5:	8b 02                	mov    (%edx),%eax
f0100db7:	8b 52 04             	mov    0x4(%edx),%edx
f0100dba:	eb 22                	jmp    f0100dde <getuint+0x38>
	else if (lflag)
f0100dbc:	85 d2                	test   %edx,%edx
f0100dbe:	74 10                	je     f0100dd0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100dc0:	8b 10                	mov    (%eax),%edx
f0100dc2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dc5:	89 08                	mov    %ecx,(%eax)
f0100dc7:	8b 02                	mov    (%edx),%eax
f0100dc9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dce:	eb 0e                	jmp    f0100dde <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100dd0:	8b 10                	mov    (%eax),%edx
f0100dd2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dd5:	89 08                	mov    %ecx,(%eax)
f0100dd7:	8b 02                	mov    (%edx),%eax
f0100dd9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100dde:	5d                   	pop    %ebp
f0100ddf:	c3                   	ret    

f0100de0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100de0:	55                   	push   %ebp
f0100de1:	89 e5                	mov    %esp,%ebp
f0100de3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100de6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100dea:	8b 10                	mov    (%eax),%edx
f0100dec:	3b 50 04             	cmp    0x4(%eax),%edx
f0100def:	73 0a                	jae    f0100dfb <sprintputch+0x1b>
		*b->buf++ = ch;
f0100df1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100df4:	88 0a                	mov    %cl,(%edx)
f0100df6:	83 c2 01             	add    $0x1,%edx
f0100df9:	89 10                	mov    %edx,(%eax)
}
f0100dfb:	5d                   	pop    %ebp
f0100dfc:	c3                   	ret    

f0100dfd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dfd:	55                   	push   %ebp
f0100dfe:	89 e5                	mov    %esp,%ebp
f0100e00:	57                   	push   %edi
f0100e01:	56                   	push   %esi
f0100e02:	53                   	push   %ebx
f0100e03:	83 ec 5c             	sub    $0x5c,%esp
f0100e06:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100e09:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e0c:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100e0f:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0100e16:	eb 19                	jmp    f0100e31 <vprintfmt+0x34>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e18:	85 c0                	test   %eax,%eax
f0100e1a:	0f 84 00 04 00 00    	je     f0101220 <vprintfmt+0x423>
				return;
			putch(ch, putdat);
f0100e20:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e24:	89 04 24             	mov    %eax,(%esp)
f0100e27:	ff d7                	call   *%edi
f0100e29:	eb 06                	jmp    f0100e31 <vprintfmt+0x34>
f0100e2b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e2e:	8b 5d d0             	mov    -0x30(%ebp),%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e31:	0f b6 03             	movzbl (%ebx),%eax
f0100e34:	83 c3 01             	add    $0x1,%ebx
f0100e37:	83 f8 25             	cmp    $0x25,%eax
f0100e3a:	75 dc                	jne    f0100e18 <vprintfmt+0x1b>
f0100e3c:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100e40:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e47:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100e4e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100e55:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100e5c:	eb 06                	jmp    f0100e64 <vprintfmt+0x67>
f0100e5e:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100e62:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e64:	0f b6 0b             	movzbl (%ebx),%ecx
f0100e67:	0f b6 d1             	movzbl %cl,%edx
f0100e6a:	8d 43 01             	lea    0x1(%ebx),%eax
f0100e6d:	83 e9 23             	sub    $0x23,%ecx
f0100e70:	80 f9 55             	cmp    $0x55,%cl
f0100e73:	0f 87 8a 03 00 00    	ja     f0101203 <vprintfmt+0x406>
f0100e79:	0f b6 c9             	movzbl %cl,%ecx
f0100e7c:	ff 24 8d bc 1f 10 f0 	jmp    *-0xfefe044(,%ecx,4)
f0100e83:	c6 45 e4 2b          	movb   $0x2b,-0x1c(%ebp)
f0100e87:	eb d9                	jmp    f0100e62 <vprintfmt+0x65>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e89:	83 ea 30             	sub    $0x30,%edx
f0100e8c:	89 55 cc             	mov    %edx,-0x34(%ebp)
				ch = *fmt;
f0100e8f:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100e92:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100e95:	83 f9 09             	cmp    $0x9,%ecx
f0100e98:	76 08                	jbe    f0100ea2 <vprintfmt+0xa5>
f0100e9a:	eb 4c                	jmp    f0100ee8 <vprintfmt+0xeb>
f0100e9c:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
    		goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
			goto reswitch;
f0100ea0:	eb c0                	jmp    f0100e62 <vprintfmt+0x65>
f0100ea2:	8b 4d cc             	mov    -0x34(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ea5:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100ea8:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100eab:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100eaf:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100eb2:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100eb5:	83 fb 09             	cmp    $0x9,%ebx
f0100eb8:	76 eb                	jbe    f0100ea5 <vprintfmt+0xa8>
f0100eba:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100ebd:	eb 29                	jmp    f0100ee8 <vprintfmt+0xeb>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ebf:	8b 55 14             	mov    0x14(%ebp),%edx
f0100ec2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ec5:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100ec8:	8b 12                	mov    (%edx),%edx
f0100eca:	89 55 cc             	mov    %edx,-0x34(%ebp)
			goto process_precision;
f0100ecd:	eb 19                	jmp    f0100ee8 <vprintfmt+0xeb>

		case '.':
			if (width < 0)
f0100ecf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100ed2:	c1 fa 1f             	sar    $0x1f,%edx
f0100ed5:	f7 d2                	not    %edx
f0100ed7:	21 55 d4             	and    %edx,-0x2c(%ebp)
f0100eda:	eb 86                	jmp    f0100e62 <vprintfmt+0x65>
f0100edc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100ee3:	e9 7a ff ff ff       	jmp    f0100e62 <vprintfmt+0x65>

		process_precision:
			if (width < 0)
f0100ee8:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100eec:	0f 89 70 ff ff ff    	jns    f0100e62 <vprintfmt+0x65>
f0100ef2:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100ef5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100ef8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100efb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100efe:	e9 5f ff ff ff       	jmp    f0100e62 <vprintfmt+0x65>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f03:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f07:	e9 56 ff ff ff       	jmp    f0100e62 <vprintfmt+0x65>
f0100f0c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f12:	8d 50 04             	lea    0x4(%eax),%edx
f0100f15:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f18:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f1c:	8b 00                	mov    (%eax),%eax
f0100f1e:	89 04 24             	mov    %eax,(%esp)
f0100f21:	ff d7                	call   *%edi
f0100f23:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			break;
f0100f26:	e9 06 ff ff ff       	jmp    f0100e31 <vprintfmt+0x34>
f0100f2b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f31:	8d 50 04             	lea    0x4(%eax),%edx
f0100f34:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f37:	8b 00                	mov    (%eax),%eax
f0100f39:	89 c2                	mov    %eax,%edx
f0100f3b:	c1 fa 1f             	sar    $0x1f,%edx
f0100f3e:	31 d0                	xor    %edx,%eax
f0100f40:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f42:	83 f8 06             	cmp    $0x6,%eax
f0100f45:	7f 0b                	jg     f0100f52 <vprintfmt+0x155>
f0100f47:	8b 14 85 14 21 10 f0 	mov    -0xfefdeec(,%eax,4),%edx
f0100f4e:	85 d2                	test   %edx,%edx
f0100f50:	75 20                	jne    f0100f72 <vprintfmt+0x175>
				printfmt(putch, putdat, "error %d", err);
f0100f52:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f56:	c7 44 24 08 3e 1f 10 	movl   $0xf0101f3e,0x8(%esp)
f0100f5d:	f0 
f0100f5e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f62:	89 3c 24             	mov    %edi,(%esp)
f0100f65:	e8 3e 03 00 00       	call   f01012a8 <printfmt>
f0100f6a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f6d:	e9 bf fe ff ff       	jmp    f0100e31 <vprintfmt+0x34>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0100f72:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f76:	c7 44 24 08 47 1f 10 	movl   $0xf0101f47,0x8(%esp)
f0100f7d:	f0 
f0100f7e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f82:	89 3c 24             	mov    %edi,(%esp)
f0100f85:	e8 1e 03 00 00       	call   f01012a8 <printfmt>
f0100f8a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0100f8d:	e9 9f fe ff ff       	jmp    f0100e31 <vprintfmt+0x34>
f0100f92:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f95:	89 c3                	mov    %eax,%ebx
f0100f97:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f9d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fa0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa3:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fa9:	8b 00                	mov    (%eax),%eax
f0100fab:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fae:	85 c0                	test   %eax,%eax
f0100fb0:	75 07                	jne    f0100fb9 <vprintfmt+0x1bc>
f0100fb2:	c7 45 e0 4a 1f 10 f0 	movl   $0xf0101f4a,-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f0100fb9:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f0100fbd:	7e 06                	jle    f0100fc5 <vprintfmt+0x1c8>
f0100fbf:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0100fc3:	75 13                	jne    f0100fd8 <vprintfmt+0x1db>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fc5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100fc8:	0f be 02             	movsbl (%edx),%eax
f0100fcb:	85 c0                	test   %eax,%eax
f0100fcd:	0f 85 9f 00 00 00    	jne    f0101072 <vprintfmt+0x275>
f0100fd3:	e9 8f 00 00 00       	jmp    f0101067 <vprintfmt+0x26a>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fd8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100fdc:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fdf:	89 0c 24             	mov    %ecx,(%esp)
f0100fe2:	e8 e4 03 00 00       	call   f01013cb <strnlen>
f0100fe7:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100fea:	29 c2                	sub    %eax,%edx
f0100fec:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100fef:	85 d2                	test   %edx,%edx
f0100ff1:	7e d2                	jle    f0100fc5 <vprintfmt+0x1c8>
					putch(padc, putdat);
f0100ff3:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0100ff7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100ffa:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f0100ffd:	89 d3                	mov    %edx,%ebx
f0100fff:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101003:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101006:	89 04 24             	mov    %eax,(%esp)
f0101009:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010100b:	83 eb 01             	sub    $0x1,%ebx
f010100e:	85 db                	test   %ebx,%ebx
f0101010:	7f ed                	jg     f0100fff <vprintfmt+0x202>
f0101012:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101015:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f010101c:	eb a7                	jmp    f0100fc5 <vprintfmt+0x1c8>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010101e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101022:	74 1b                	je     f010103f <vprintfmt+0x242>
f0101024:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101027:	83 fa 5e             	cmp    $0x5e,%edx
f010102a:	76 13                	jbe    f010103f <vprintfmt+0x242>
					putch('?', putdat);
f010102c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010102f:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101033:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010103a:	ff 55 e4             	call   *-0x1c(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010103d:	eb 0d                	jmp    f010104c <vprintfmt+0x24f>
					putch('?', putdat);
				else
					putch(ch, putdat);
f010103f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101042:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101046:	89 04 24             	mov    %eax,(%esp)
f0101049:	ff 55 e4             	call   *-0x1c(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010104c:	83 ef 01             	sub    $0x1,%edi
f010104f:	0f be 03             	movsbl (%ebx),%eax
f0101052:	85 c0                	test   %eax,%eax
f0101054:	74 05                	je     f010105b <vprintfmt+0x25e>
f0101056:	83 c3 01             	add    $0x1,%ebx
f0101059:	eb 2e                	jmp    f0101089 <vprintfmt+0x28c>
f010105b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010105e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101061:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101064:	8b 5d cc             	mov    -0x34(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101067:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010106b:	7f 33                	jg     f01010a0 <vprintfmt+0x2a3>
f010106d:	e9 bc fd ff ff       	jmp    f0100e2e <vprintfmt+0x31>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101072:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101075:	83 c2 01             	add    $0x1,%edx
f0101078:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f010107b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010107e:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101081:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101084:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0101087:	89 d3                	mov    %edx,%ebx
f0101089:	85 f6                	test   %esi,%esi
f010108b:	78 91                	js     f010101e <vprintfmt+0x221>
f010108d:	83 ee 01             	sub    $0x1,%esi
f0101090:	79 8c                	jns    f010101e <vprintfmt+0x221>
f0101092:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101095:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101098:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010109b:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f010109e:	eb c7                	jmp    f0101067 <vprintfmt+0x26a>
f01010a0:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01010a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010aa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010b1:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010b3:	83 eb 01             	sub    $0x1,%ebx
f01010b6:	85 db                	test   %ebx,%ebx
f01010b8:	7f ec                	jg     f01010a6 <vprintfmt+0x2a9>
f01010ba:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010bd:	e9 6f fd ff ff       	jmp    f0100e31 <vprintfmt+0x34>
f01010c2:	89 45 d0             	mov    %eax,-0x30(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010c5:	83 7d e0 01          	cmpl   $0x1,-0x20(%ebp)
f01010c9:	7e 16                	jle    f01010e1 <vprintfmt+0x2e4>
		return va_arg(*ap, long long);
f01010cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ce:	8d 50 08             	lea    0x8(%eax),%edx
f01010d1:	89 55 14             	mov    %edx,0x14(%ebp)
f01010d4:	8b 10                	mov    (%eax),%edx
f01010d6:	8b 48 04             	mov    0x4(%eax),%ecx
f01010d9:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01010dc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010df:	eb 34                	jmp    f0101115 <vprintfmt+0x318>
	else if (lflag)
f01010e1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010e5:	74 18                	je     f01010ff <vprintfmt+0x302>
		return va_arg(*ap, long);
f01010e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ea:	8d 50 04             	lea    0x4(%eax),%edx
f01010ed:	89 55 14             	mov    %edx,0x14(%ebp)
f01010f0:	8b 00                	mov    (%eax),%eax
f01010f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f5:	89 c1                	mov    %eax,%ecx
f01010f7:	c1 f9 1f             	sar    $0x1f,%ecx
f01010fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010fd:	eb 16                	jmp    f0101115 <vprintfmt+0x318>
	else
		return va_arg(*ap, int);
f01010ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101102:	8d 50 04             	lea    0x4(%eax),%edx
f0101105:	89 55 14             	mov    %edx,0x14(%ebp)
f0101108:	8b 00                	mov    (%eax),%eax
f010110a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010110d:	89 c2                	mov    %eax,%edx
f010110f:	c1 fa 1f             	sar    $0x1f,%edx
f0101112:	89 55 dc             	mov    %edx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101115:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101118:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010111b:	bb 0a 00 00 00       	mov    $0xa,%ebx
			if ((long long) num < 0) {
f0101120:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101124:	0f 89 9a 00 00 00    	jns    f01011c4 <vprintfmt+0x3c7>
				putch('-', putdat);
f010112a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010112e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101135:	ff d7                	call   *%edi
				num = -(long long) num;
f0101137:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010113a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010113d:	f7 d8                	neg    %eax
f010113f:	83 d2 00             	adc    $0x0,%edx
f0101142:	f7 da                	neg    %edx
f0101144:	eb 7e                	jmp    f01011c4 <vprintfmt+0x3c7>
f0101146:	89 45 d0             	mov    %eax,-0x30(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101149:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010114c:	8d 45 14             	lea    0x14(%ebp),%eax
f010114f:	e8 52 fc ff ff       	call   f0100da6 <getuint>
f0101154:	bb 0a 00 00 00       	mov    $0xa,%ebx
			base = 10;
			goto number;
f0101159:	eb 69                	jmp    f01011c4 <vprintfmt+0x3c7>
f010115b:	89 45 d0             	mov    %eax,-0x30(%ebp)
			putch('X', putdat);
			break;
			*/

			// Solution for Exercise 8.
			putch('0', putdat);
f010115e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101162:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101169:	ff d7                	call   *%edi
			num = getuint(&ap, lflag);
f010116b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010116e:	8d 45 14             	lea    0x14(%ebp),%eax
f0101171:	e8 30 fc ff ff       	call   f0100da6 <getuint>
f0101176:	bb 08 00 00 00       	mov    $0x8,%ebx
			base = 8;
			goto number;
f010117b:	eb 47                	jmp    f01011c4 <vprintfmt+0x3c7>
f010117d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
f0101180:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101184:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010118b:	ff d7                	call   *%edi
			putch('x', putdat);
f010118d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101191:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101198:	ff d7                	call   *%edi
			num = (unsigned long long)
f010119a:	8b 45 14             	mov    0x14(%ebp),%eax
f010119d:	8d 50 04             	lea    0x4(%eax),%edx
f01011a0:	89 55 14             	mov    %edx,0x14(%ebp)
f01011a3:	8b 00                	mov    (%eax),%eax
f01011a5:	ba 00 00 00 00       	mov    $0x0,%edx
f01011aa:	bb 10 00 00 00       	mov    $0x10,%ebx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01011af:	eb 13                	jmp    f01011c4 <vprintfmt+0x3c7>
f01011b1:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011b4:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01011b7:	8d 45 14             	lea    0x14(%ebp),%eax
f01011ba:	e8 e7 fb ff ff       	call   f0100da6 <getuint>
f01011bf:	bb 10 00 00 00       	mov    $0x10,%ebx
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011c4:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01011c8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01011cc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01011cf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01011d3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01011d7:	89 04 24             	mov    %eax,(%esp)
f01011da:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011de:	89 f2                	mov    %esi,%edx
f01011e0:	89 f8                	mov    %edi,%eax
f01011e2:	e8 c9 fa ff ff       	call   f0100cb0 <printnum>
f01011e7:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			break;
f01011ea:	e9 42 fc ff ff       	jmp    f0100e31 <vprintfmt+0x34>
f01011ef:	89 45 d0             	mov    %eax,-0x30(%ebp)
            break;
        }

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011f2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011f6:	89 14 24             	mov    %edx,(%esp)
f01011f9:	ff d7                	call   *%edi
f01011fb:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			break;
f01011fe:	e9 2e fc ff ff       	jmp    f0100e31 <vprintfmt+0x34>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101203:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101207:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010120e:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101210:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101213:	80 38 25             	cmpb   $0x25,(%eax)
f0101216:	0f 84 15 fc ff ff    	je     f0100e31 <vprintfmt+0x34>
f010121c:	89 c3                	mov    %eax,%ebx
f010121e:	eb f0                	jmp    f0101210 <vprintfmt+0x413>
				/* do nothing */;
			break;
		}
	}
}
f0101220:	83 c4 5c             	add    $0x5c,%esp
f0101223:	5b                   	pop    %ebx
f0101224:	5e                   	pop    %esi
f0101225:	5f                   	pop    %edi
f0101226:	5d                   	pop    %ebp
f0101227:	c3                   	ret    

f0101228 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101228:	55                   	push   %ebp
f0101229:	89 e5                	mov    %esp,%ebp
f010122b:	83 ec 28             	sub    $0x28,%esp
f010122e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101231:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f0101234:	85 c0                	test   %eax,%eax
f0101236:	74 04                	je     f010123c <vsnprintf+0x14>
f0101238:	85 d2                	test   %edx,%edx
f010123a:	7f 07                	jg     f0101243 <vsnprintf+0x1b>
f010123c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101241:	eb 3b                	jmp    f010127e <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101243:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101246:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f010124a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010124d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101254:	8b 45 14             	mov    0x14(%ebp),%eax
f0101257:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010125b:	8b 45 10             	mov    0x10(%ebp),%eax
f010125e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101262:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101265:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101269:	c7 04 24 e0 0d 10 f0 	movl   $0xf0100de0,(%esp)
f0101270:	e8 88 fb ff ff       	call   f0100dfd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101275:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101278:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010127b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010127e:	c9                   	leave  
f010127f:	c3                   	ret    

f0101280 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101280:	55                   	push   %ebp
f0101281:	89 e5                	mov    %esp,%ebp
f0101283:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f0101286:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0101289:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010128d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101290:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101294:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101297:	89 44 24 04          	mov    %eax,0x4(%esp)
f010129b:	8b 45 08             	mov    0x8(%ebp),%eax
f010129e:	89 04 24             	mov    %eax,(%esp)
f01012a1:	e8 82 ff ff ff       	call   f0101228 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012a6:	c9                   	leave  
f01012a7:	c3                   	ret    

f01012a8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01012a8:	55                   	push   %ebp
f01012a9:	89 e5                	mov    %esp,%ebp
f01012ab:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f01012ae:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f01012b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012b5:	8b 45 10             	mov    0x10(%ebp),%eax
f01012b8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c6:	89 04 24             	mov    %eax,(%esp)
f01012c9:	e8 2f fb ff ff       	call   f0100dfd <vprintfmt>
	va_end(ap);
}
f01012ce:	c9                   	leave  
f01012cf:	c3                   	ret    

f01012d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	57                   	push   %edi
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 1c             	sub    $0x1c,%esp
f01012d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 10                	je     f01012f0 <readline+0x20>
		cprintf("%s", prompt);
f01012e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e4:	c7 04 24 47 1f 10 f0 	movl   $0xf0101f47,(%esp)
f01012eb:	e8 7b f6 ff ff       	call   f010096b <cprintf>

	i = 0;
	echoing = iscons(0);
f01012f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012f7:	e8 aa ef ff ff       	call   f01002a6 <iscons>
f01012fc:	89 c7                	mov    %eax,%edi
f01012fe:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101303:	e8 8d ef ff ff       	call   f0100295 <getchar>
f0101308:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010130a:	85 c0                	test   %eax,%eax
f010130c:	79 17                	jns    f0101325 <readline+0x55>
			cprintf("read error: %e\n", c);
f010130e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101312:	c7 04 24 30 21 10 f0 	movl   $0xf0102130,(%esp)
f0101319:	e8 4d f6 ff ff       	call   f010096b <cprintf>
f010131e:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f0101323:	eb 76                	jmp    f010139b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101325:	83 f8 08             	cmp    $0x8,%eax
f0101328:	74 08                	je     f0101332 <readline+0x62>
f010132a:	83 f8 7f             	cmp    $0x7f,%eax
f010132d:	8d 76 00             	lea    0x0(%esi),%esi
f0101330:	75 19                	jne    f010134b <readline+0x7b>
f0101332:	85 f6                	test   %esi,%esi
f0101334:	7e 15                	jle    f010134b <readline+0x7b>
			if (echoing)
f0101336:	85 ff                	test   %edi,%edi
f0101338:	74 0c                	je     f0101346 <readline+0x76>
				cputchar('\b');
f010133a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101341:	e8 64 f1 ff ff       	call   f01004aa <cputchar>
			i--;
f0101346:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101349:	eb b8                	jmp    f0101303 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f010134b:	83 fb 1f             	cmp    $0x1f,%ebx
f010134e:	66 90                	xchg   %ax,%ax
f0101350:	7e 23                	jle    f0101375 <readline+0xa5>
f0101352:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101358:	7f 1b                	jg     f0101375 <readline+0xa5>
			if (echoing)
f010135a:	85 ff                	test   %edi,%edi
f010135c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101360:	74 08                	je     f010136a <readline+0x9a>
				cputchar(c);
f0101362:	89 1c 24             	mov    %ebx,(%esp)
f0101365:	e8 40 f1 ff ff       	call   f01004aa <cputchar>
			buf[i++] = c;
f010136a:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101370:	83 c6 01             	add    $0x1,%esi
f0101373:	eb 8e                	jmp    f0101303 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101375:	83 fb 0a             	cmp    $0xa,%ebx
f0101378:	74 05                	je     f010137f <readline+0xaf>
f010137a:	83 fb 0d             	cmp    $0xd,%ebx
f010137d:	75 84                	jne    f0101303 <readline+0x33>
			if (echoing)
f010137f:	85 ff                	test   %edi,%edi
f0101381:	74 0c                	je     f010138f <readline+0xbf>
				cputchar('\n');
f0101383:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010138a:	e8 1b f1 ff ff       	call   f01004aa <cputchar>
			buf[i] = 0;
f010138f:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
f0101396:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
			return buf;
		}
	}
}
f010139b:	83 c4 1c             	add    $0x1c,%esp
f010139e:	5b                   	pop    %ebx
f010139f:	5e                   	pop    %esi
f01013a0:	5f                   	pop    %edi
f01013a1:	5d                   	pop    %ebp
f01013a2:	c3                   	ret    
	...

f01013b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013b0:	55                   	push   %ebp
f01013b1:	89 e5                	mov    %esp,%ebp
f01013b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013bb:	80 3a 00             	cmpb   $0x0,(%edx)
f01013be:	74 09                	je     f01013c9 <strlen+0x19>
		n++;
f01013c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013c7:	75 f7                	jne    f01013c0 <strlen+0x10>
		n++;
	return n;
}
f01013c9:	5d                   	pop    %ebp
f01013ca:	c3                   	ret    

f01013cb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013cb:	55                   	push   %ebp
f01013cc:	89 e5                	mov    %esp,%ebp
f01013ce:	53                   	push   %ebx
f01013cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013d5:	85 c9                	test   %ecx,%ecx
f01013d7:	74 19                	je     f01013f2 <strnlen+0x27>
f01013d9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013dc:	74 14                	je     f01013f2 <strnlen+0x27>
f01013de:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01013e3:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013e6:	39 c8                	cmp    %ecx,%eax
f01013e8:	74 0d                	je     f01013f7 <strnlen+0x2c>
f01013ea:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f01013ee:	75 f3                	jne    f01013e3 <strnlen+0x18>
f01013f0:	eb 05                	jmp    f01013f7 <strnlen+0x2c>
f01013f2:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013f7:	5b                   	pop    %ebx
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    

f01013fa <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013fa:	55                   	push   %ebp
f01013fb:	89 e5                	mov    %esp,%ebp
f01013fd:	53                   	push   %ebx
f01013fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101401:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101404:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101409:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010140d:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101410:	83 c2 01             	add    $0x1,%edx
f0101413:	84 c9                	test   %cl,%cl
f0101415:	75 f2                	jne    f0101409 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101417:	5b                   	pop    %ebx
f0101418:	5d                   	pop    %ebp
f0101419:	c3                   	ret    

f010141a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010141a:	55                   	push   %ebp
f010141b:	89 e5                	mov    %esp,%ebp
f010141d:	56                   	push   %esi
f010141e:	53                   	push   %ebx
f010141f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101422:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101425:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101428:	85 f6                	test   %esi,%esi
f010142a:	74 18                	je     f0101444 <strncpy+0x2a>
f010142c:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101431:	0f b6 1a             	movzbl (%edx),%ebx
f0101434:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101437:	80 3a 01             	cmpb   $0x1,(%edx)
f010143a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010143d:	83 c1 01             	add    $0x1,%ecx
f0101440:	39 ce                	cmp    %ecx,%esi
f0101442:	77 ed                	ja     f0101431 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101444:	5b                   	pop    %ebx
f0101445:	5e                   	pop    %esi
f0101446:	5d                   	pop    %ebp
f0101447:	c3                   	ret    

f0101448 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101448:	55                   	push   %ebp
f0101449:	89 e5                	mov    %esp,%ebp
f010144b:	56                   	push   %esi
f010144c:	53                   	push   %ebx
f010144d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101450:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101453:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101456:	89 f0                	mov    %esi,%eax
f0101458:	85 c9                	test   %ecx,%ecx
f010145a:	74 27                	je     f0101483 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f010145c:	83 e9 01             	sub    $0x1,%ecx
f010145f:	74 1d                	je     f010147e <strlcpy+0x36>
f0101461:	0f b6 1a             	movzbl (%edx),%ebx
f0101464:	84 db                	test   %bl,%bl
f0101466:	74 16                	je     f010147e <strlcpy+0x36>
			*dst++ = *src++;
f0101468:	88 18                	mov    %bl,(%eax)
f010146a:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010146d:	83 e9 01             	sub    $0x1,%ecx
f0101470:	74 0e                	je     f0101480 <strlcpy+0x38>
			*dst++ = *src++;
f0101472:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101475:	0f b6 1a             	movzbl (%edx),%ebx
f0101478:	84 db                	test   %bl,%bl
f010147a:	75 ec                	jne    f0101468 <strlcpy+0x20>
f010147c:	eb 02                	jmp    f0101480 <strlcpy+0x38>
f010147e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101480:	c6 00 00             	movb   $0x0,(%eax)
f0101483:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101485:	5b                   	pop    %ebx
f0101486:	5e                   	pop    %esi
f0101487:	5d                   	pop    %ebp
f0101488:	c3                   	ret    

f0101489 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101489:	55                   	push   %ebp
f010148a:	89 e5                	mov    %esp,%ebp
f010148c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010148f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101492:	0f b6 01             	movzbl (%ecx),%eax
f0101495:	84 c0                	test   %al,%al
f0101497:	74 15                	je     f01014ae <strcmp+0x25>
f0101499:	3a 02                	cmp    (%edx),%al
f010149b:	75 11                	jne    f01014ae <strcmp+0x25>
		p++, q++;
f010149d:	83 c1 01             	add    $0x1,%ecx
f01014a0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014a3:	0f b6 01             	movzbl (%ecx),%eax
f01014a6:	84 c0                	test   %al,%al
f01014a8:	74 04                	je     f01014ae <strcmp+0x25>
f01014aa:	3a 02                	cmp    (%edx),%al
f01014ac:	74 ef                	je     f010149d <strcmp+0x14>
f01014ae:	0f b6 c0             	movzbl %al,%eax
f01014b1:	0f b6 12             	movzbl (%edx),%edx
f01014b4:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014b6:	5d                   	pop    %ebp
f01014b7:	c3                   	ret    

f01014b8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014b8:	55                   	push   %ebp
f01014b9:	89 e5                	mov    %esp,%ebp
f01014bb:	53                   	push   %ebx
f01014bc:	8b 55 08             	mov    0x8(%ebp),%edx
f01014bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014c2:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f01014c5:	85 c0                	test   %eax,%eax
f01014c7:	74 23                	je     f01014ec <strncmp+0x34>
f01014c9:	0f b6 1a             	movzbl (%edx),%ebx
f01014cc:	84 db                	test   %bl,%bl
f01014ce:	74 24                	je     f01014f4 <strncmp+0x3c>
f01014d0:	3a 19                	cmp    (%ecx),%bl
f01014d2:	75 20                	jne    f01014f4 <strncmp+0x3c>
f01014d4:	83 e8 01             	sub    $0x1,%eax
f01014d7:	74 13                	je     f01014ec <strncmp+0x34>
		n--, p++, q++;
f01014d9:	83 c2 01             	add    $0x1,%edx
f01014dc:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014df:	0f b6 1a             	movzbl (%edx),%ebx
f01014e2:	84 db                	test   %bl,%bl
f01014e4:	74 0e                	je     f01014f4 <strncmp+0x3c>
f01014e6:	3a 19                	cmp    (%ecx),%bl
f01014e8:	74 ea                	je     f01014d4 <strncmp+0x1c>
f01014ea:	eb 08                	jmp    f01014f4 <strncmp+0x3c>
f01014ec:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014f1:	5b                   	pop    %ebx
f01014f2:	5d                   	pop    %ebp
f01014f3:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f4:	0f b6 02             	movzbl (%edx),%eax
f01014f7:	0f b6 11             	movzbl (%ecx),%edx
f01014fa:	29 d0                	sub    %edx,%eax
f01014fc:	eb f3                	jmp    f01014f1 <strncmp+0x39>

f01014fe <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014fe:	55                   	push   %ebp
f01014ff:	89 e5                	mov    %esp,%ebp
f0101501:	8b 45 08             	mov    0x8(%ebp),%eax
f0101504:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101508:	0f b6 10             	movzbl (%eax),%edx
f010150b:	84 d2                	test   %dl,%dl
f010150d:	74 15                	je     f0101524 <strchr+0x26>
		if (*s == c)
f010150f:	38 ca                	cmp    %cl,%dl
f0101511:	75 07                	jne    f010151a <strchr+0x1c>
f0101513:	eb 14                	jmp    f0101529 <strchr+0x2b>
f0101515:	38 ca                	cmp    %cl,%dl
f0101517:	90                   	nop
f0101518:	74 0f                	je     f0101529 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010151a:	83 c0 01             	add    $0x1,%eax
f010151d:	0f b6 10             	movzbl (%eax),%edx
f0101520:	84 d2                	test   %dl,%dl
f0101522:	75 f1                	jne    f0101515 <strchr+0x17>
f0101524:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f0101529:	5d                   	pop    %ebp
f010152a:	c3                   	ret    

f010152b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010152b:	55                   	push   %ebp
f010152c:	89 e5                	mov    %esp,%ebp
f010152e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101531:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101535:	0f b6 10             	movzbl (%eax),%edx
f0101538:	84 d2                	test   %dl,%dl
f010153a:	74 18                	je     f0101554 <strfind+0x29>
		if (*s == c)
f010153c:	38 ca                	cmp    %cl,%dl
f010153e:	75 0a                	jne    f010154a <strfind+0x1f>
f0101540:	eb 12                	jmp    f0101554 <strfind+0x29>
f0101542:	38 ca                	cmp    %cl,%dl
f0101544:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101548:	74 0a                	je     f0101554 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010154a:	83 c0 01             	add    $0x1,%eax
f010154d:	0f b6 10             	movzbl (%eax),%edx
f0101550:	84 d2                	test   %dl,%dl
f0101552:	75 ee                	jne    f0101542 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101554:	5d                   	pop    %ebp
f0101555:	c3                   	ret    

f0101556 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101556:	55                   	push   %ebp
f0101557:	89 e5                	mov    %esp,%ebp
f0101559:	83 ec 0c             	sub    $0xc,%esp
f010155c:	89 1c 24             	mov    %ebx,(%esp)
f010155f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101563:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101567:	8b 7d 08             	mov    0x8(%ebp),%edi
f010156a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101570:	85 c9                	test   %ecx,%ecx
f0101572:	74 30                	je     f01015a4 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101574:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010157a:	75 25                	jne    f01015a1 <memset+0x4b>
f010157c:	f6 c1 03             	test   $0x3,%cl
f010157f:	75 20                	jne    f01015a1 <memset+0x4b>
		c &= 0xFF;
f0101581:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101584:	89 d3                	mov    %edx,%ebx
f0101586:	c1 e3 08             	shl    $0x8,%ebx
f0101589:	89 d6                	mov    %edx,%esi
f010158b:	c1 e6 18             	shl    $0x18,%esi
f010158e:	89 d0                	mov    %edx,%eax
f0101590:	c1 e0 10             	shl    $0x10,%eax
f0101593:	09 f0                	or     %esi,%eax
f0101595:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101597:	09 d8                	or     %ebx,%eax
f0101599:	c1 e9 02             	shr    $0x2,%ecx
f010159c:	fc                   	cld    
f010159d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010159f:	eb 03                	jmp    f01015a4 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015a1:	fc                   	cld    
f01015a2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015a4:	89 f8                	mov    %edi,%eax
f01015a6:	8b 1c 24             	mov    (%esp),%ebx
f01015a9:	8b 74 24 04          	mov    0x4(%esp),%esi
f01015ad:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01015b1:	89 ec                	mov    %ebp,%esp
f01015b3:	5d                   	pop    %ebp
f01015b4:	c3                   	ret    

f01015b5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015b5:	55                   	push   %ebp
f01015b6:	89 e5                	mov    %esp,%ebp
f01015b8:	83 ec 08             	sub    $0x8,%esp
f01015bb:	89 34 24             	mov    %esi,(%esp)
f01015be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01015c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f01015c8:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f01015cb:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f01015cd:	39 c6                	cmp    %eax,%esi
f01015cf:	73 35                	jae    f0101606 <memmove+0x51>
f01015d1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015d4:	39 d0                	cmp    %edx,%eax
f01015d6:	73 2e                	jae    f0101606 <memmove+0x51>
		s += n;
		d += n;
f01015d8:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015da:	f6 c2 03             	test   $0x3,%dl
f01015dd:	75 1b                	jne    f01015fa <memmove+0x45>
f01015df:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015e5:	75 13                	jne    f01015fa <memmove+0x45>
f01015e7:	f6 c1 03             	test   $0x3,%cl
f01015ea:	75 0e                	jne    f01015fa <memmove+0x45>
			asm volatile("std; rep movsl\n"
f01015ec:	83 ef 04             	sub    $0x4,%edi
f01015ef:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015f2:	c1 e9 02             	shr    $0x2,%ecx
f01015f5:	fd                   	std    
f01015f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015f8:	eb 09                	jmp    f0101603 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015fa:	83 ef 01             	sub    $0x1,%edi
f01015fd:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101600:	fd                   	std    
f0101601:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101603:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101604:	eb 20                	jmp    f0101626 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101606:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010160c:	75 15                	jne    f0101623 <memmove+0x6e>
f010160e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101614:	75 0d                	jne    f0101623 <memmove+0x6e>
f0101616:	f6 c1 03             	test   $0x3,%cl
f0101619:	75 08                	jne    f0101623 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f010161b:	c1 e9 02             	shr    $0x2,%ecx
f010161e:	fc                   	cld    
f010161f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101621:	eb 03                	jmp    f0101626 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101623:	fc                   	cld    
f0101624:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101626:	8b 34 24             	mov    (%esp),%esi
f0101629:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010162d:	89 ec                	mov    %ebp,%esp
f010162f:	5d                   	pop    %ebp
f0101630:	c3                   	ret    

f0101631 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101631:	55                   	push   %ebp
f0101632:	89 e5                	mov    %esp,%ebp
f0101634:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101637:	8b 45 10             	mov    0x10(%ebp),%eax
f010163a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010163e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101641:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101645:	8b 45 08             	mov    0x8(%ebp),%eax
f0101648:	89 04 24             	mov    %eax,(%esp)
f010164b:	e8 65 ff ff ff       	call   f01015b5 <memmove>
}
f0101650:	c9                   	leave  
f0101651:	c3                   	ret    

f0101652 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101652:	55                   	push   %ebp
f0101653:	89 e5                	mov    %esp,%ebp
f0101655:	57                   	push   %edi
f0101656:	56                   	push   %esi
f0101657:	53                   	push   %ebx
f0101658:	8b 75 08             	mov    0x8(%ebp),%esi
f010165b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010165e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101661:	85 c9                	test   %ecx,%ecx
f0101663:	74 36                	je     f010169b <memcmp+0x49>
		if (*s1 != *s2)
f0101665:	0f b6 06             	movzbl (%esi),%eax
f0101668:	0f b6 1f             	movzbl (%edi),%ebx
f010166b:	38 d8                	cmp    %bl,%al
f010166d:	74 20                	je     f010168f <memcmp+0x3d>
f010166f:	eb 14                	jmp    f0101685 <memcmp+0x33>
f0101671:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101676:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f010167b:	83 c2 01             	add    $0x1,%edx
f010167e:	83 e9 01             	sub    $0x1,%ecx
f0101681:	38 d8                	cmp    %bl,%al
f0101683:	74 12                	je     f0101697 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101685:	0f b6 c0             	movzbl %al,%eax
f0101688:	0f b6 db             	movzbl %bl,%ebx
f010168b:	29 d8                	sub    %ebx,%eax
f010168d:	eb 11                	jmp    f01016a0 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010168f:	83 e9 01             	sub    $0x1,%ecx
f0101692:	ba 00 00 00 00       	mov    $0x0,%edx
f0101697:	85 c9                	test   %ecx,%ecx
f0101699:	75 d6                	jne    f0101671 <memcmp+0x1f>
f010169b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f01016a0:	5b                   	pop    %ebx
f01016a1:	5e                   	pop    %esi
f01016a2:	5f                   	pop    %edi
f01016a3:	5d                   	pop    %ebp
f01016a4:	c3                   	ret    

f01016a5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016a5:	55                   	push   %ebp
f01016a6:	89 e5                	mov    %esp,%ebp
f01016a8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01016ab:	89 c2                	mov    %eax,%edx
f01016ad:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016b0:	39 d0                	cmp    %edx,%eax
f01016b2:	73 15                	jae    f01016c9 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016b4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01016b8:	38 08                	cmp    %cl,(%eax)
f01016ba:	75 06                	jne    f01016c2 <memfind+0x1d>
f01016bc:	eb 0b                	jmp    f01016c9 <memfind+0x24>
f01016be:	38 08                	cmp    %cl,(%eax)
f01016c0:	74 07                	je     f01016c9 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016c2:	83 c0 01             	add    $0x1,%eax
f01016c5:	39 c2                	cmp    %eax,%edx
f01016c7:	77 f5                	ja     f01016be <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016c9:	5d                   	pop    %ebp
f01016ca:	c3                   	ret    

f01016cb <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016cb:	55                   	push   %ebp
f01016cc:	89 e5                	mov    %esp,%ebp
f01016ce:	57                   	push   %edi
f01016cf:	56                   	push   %esi
f01016d0:	53                   	push   %ebx
f01016d1:	83 ec 04             	sub    $0x4,%esp
f01016d4:	8b 55 08             	mov    0x8(%ebp),%edx
f01016d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016da:	0f b6 02             	movzbl (%edx),%eax
f01016dd:	3c 20                	cmp    $0x20,%al
f01016df:	74 04                	je     f01016e5 <strtol+0x1a>
f01016e1:	3c 09                	cmp    $0x9,%al
f01016e3:	75 0e                	jne    f01016f3 <strtol+0x28>
		s++;
f01016e5:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016e8:	0f b6 02             	movzbl (%edx),%eax
f01016eb:	3c 20                	cmp    $0x20,%al
f01016ed:	74 f6                	je     f01016e5 <strtol+0x1a>
f01016ef:	3c 09                	cmp    $0x9,%al
f01016f1:	74 f2                	je     f01016e5 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016f3:	3c 2b                	cmp    $0x2b,%al
f01016f5:	75 0c                	jne    f0101703 <strtol+0x38>
		s++;
f01016f7:	83 c2 01             	add    $0x1,%edx
f01016fa:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0101701:	eb 15                	jmp    f0101718 <strtol+0x4d>
	else if (*s == '-')
f0101703:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f010170a:	3c 2d                	cmp    $0x2d,%al
f010170c:	75 0a                	jne    f0101718 <strtol+0x4d>
		s++, neg = 1;
f010170e:	83 c2 01             	add    $0x1,%edx
f0101711:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101718:	85 db                	test   %ebx,%ebx
f010171a:	0f 94 c0             	sete   %al
f010171d:	74 05                	je     f0101724 <strtol+0x59>
f010171f:	83 fb 10             	cmp    $0x10,%ebx
f0101722:	75 18                	jne    f010173c <strtol+0x71>
f0101724:	80 3a 30             	cmpb   $0x30,(%edx)
f0101727:	75 13                	jne    f010173c <strtol+0x71>
f0101729:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010172d:	8d 76 00             	lea    0x0(%esi),%esi
f0101730:	75 0a                	jne    f010173c <strtol+0x71>
		s += 2, base = 16;
f0101732:	83 c2 02             	add    $0x2,%edx
f0101735:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010173a:	eb 15                	jmp    f0101751 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010173c:	84 c0                	test   %al,%al
f010173e:	66 90                	xchg   %ax,%ax
f0101740:	74 0f                	je     f0101751 <strtol+0x86>
f0101742:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101747:	80 3a 30             	cmpb   $0x30,(%edx)
f010174a:	75 05                	jne    f0101751 <strtol+0x86>
		s++, base = 8;
f010174c:	83 c2 01             	add    $0x1,%edx
f010174f:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101751:	b8 00 00 00 00       	mov    $0x0,%eax
f0101756:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101758:	0f b6 0a             	movzbl (%edx),%ecx
f010175b:	89 cf                	mov    %ecx,%edi
f010175d:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101760:	80 fb 09             	cmp    $0x9,%bl
f0101763:	77 08                	ja     f010176d <strtol+0xa2>
			dig = *s - '0';
f0101765:	0f be c9             	movsbl %cl,%ecx
f0101768:	83 e9 30             	sub    $0x30,%ecx
f010176b:	eb 1e                	jmp    f010178b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f010176d:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101770:	80 fb 19             	cmp    $0x19,%bl
f0101773:	77 08                	ja     f010177d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101775:	0f be c9             	movsbl %cl,%ecx
f0101778:	83 e9 57             	sub    $0x57,%ecx
f010177b:	eb 0e                	jmp    f010178b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f010177d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101780:	80 fb 19             	cmp    $0x19,%bl
f0101783:	77 15                	ja     f010179a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101785:	0f be c9             	movsbl %cl,%ecx
f0101788:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010178b:	39 f1                	cmp    %esi,%ecx
f010178d:	7d 0b                	jge    f010179a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f010178f:	83 c2 01             	add    $0x1,%edx
f0101792:	0f af c6             	imul   %esi,%eax
f0101795:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101798:	eb be                	jmp    f0101758 <strtol+0x8d>
f010179a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010179c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017a0:	74 05                	je     f01017a7 <strtol+0xdc>
		*endptr = (char *) s;
f01017a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017a5:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01017a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01017ab:	74 04                	je     f01017b1 <strtol+0xe6>
f01017ad:	89 c8                	mov    %ecx,%eax
f01017af:	f7 d8                	neg    %eax
}
f01017b1:	83 c4 04             	add    $0x4,%esp
f01017b4:	5b                   	pop    %ebx
f01017b5:	5e                   	pop    %esi
f01017b6:	5f                   	pop    %edi
f01017b7:	5d                   	pop    %ebp
f01017b8:	c3                   	ret    
f01017b9:	00 00                	add    %al,(%eax)
f01017bb:	00 00                	add    %al,(%eax)
f01017bd:	00 00                	add    %al,(%eax)
	...

f01017c0 <__udivdi3>:
f01017c0:	55                   	push   %ebp
f01017c1:	89 e5                	mov    %esp,%ebp
f01017c3:	57                   	push   %edi
f01017c4:	56                   	push   %esi
f01017c5:	83 ec 10             	sub    $0x10,%esp
f01017c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01017cb:	8b 55 08             	mov    0x8(%ebp),%edx
f01017ce:	8b 75 10             	mov    0x10(%ebp),%esi
f01017d1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01017d4:	85 c0                	test   %eax,%eax
f01017d6:	89 55 f0             	mov    %edx,-0x10(%ebp)
f01017d9:	75 35                	jne    f0101810 <__udivdi3+0x50>
f01017db:	39 fe                	cmp    %edi,%esi
f01017dd:	77 61                	ja     f0101840 <__udivdi3+0x80>
f01017df:	85 f6                	test   %esi,%esi
f01017e1:	75 0b                	jne    f01017ee <__udivdi3+0x2e>
f01017e3:	b8 01 00 00 00       	mov    $0x1,%eax
f01017e8:	31 d2                	xor    %edx,%edx
f01017ea:	f7 f6                	div    %esi
f01017ec:	89 c6                	mov    %eax,%esi
f01017ee:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f01017f1:	31 d2                	xor    %edx,%edx
f01017f3:	89 f8                	mov    %edi,%eax
f01017f5:	f7 f6                	div    %esi
f01017f7:	89 c7                	mov    %eax,%edi
f01017f9:	89 c8                	mov    %ecx,%eax
f01017fb:	f7 f6                	div    %esi
f01017fd:	89 c1                	mov    %eax,%ecx
f01017ff:	89 fa                	mov    %edi,%edx
f0101801:	89 c8                	mov    %ecx,%eax
f0101803:	83 c4 10             	add    $0x10,%esp
f0101806:	5e                   	pop    %esi
f0101807:	5f                   	pop    %edi
f0101808:	5d                   	pop    %ebp
f0101809:	c3                   	ret    
f010180a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101810:	39 f8                	cmp    %edi,%eax
f0101812:	77 1c                	ja     f0101830 <__udivdi3+0x70>
f0101814:	0f bd d0             	bsr    %eax,%edx
f0101817:	83 f2 1f             	xor    $0x1f,%edx
f010181a:	89 55 f4             	mov    %edx,-0xc(%ebp)
f010181d:	75 39                	jne    f0101858 <__udivdi3+0x98>
f010181f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101822:	0f 86 a0 00 00 00    	jbe    f01018c8 <__udivdi3+0x108>
f0101828:	39 f8                	cmp    %edi,%eax
f010182a:	0f 82 98 00 00 00    	jb     f01018c8 <__udivdi3+0x108>
f0101830:	31 ff                	xor    %edi,%edi
f0101832:	31 c9                	xor    %ecx,%ecx
f0101834:	89 c8                	mov    %ecx,%eax
f0101836:	89 fa                	mov    %edi,%edx
f0101838:	83 c4 10             	add    $0x10,%esp
f010183b:	5e                   	pop    %esi
f010183c:	5f                   	pop    %edi
f010183d:	5d                   	pop    %ebp
f010183e:	c3                   	ret    
f010183f:	90                   	nop
f0101840:	89 d1                	mov    %edx,%ecx
f0101842:	89 fa                	mov    %edi,%edx
f0101844:	89 c8                	mov    %ecx,%eax
f0101846:	31 ff                	xor    %edi,%edi
f0101848:	f7 f6                	div    %esi
f010184a:	89 c1                	mov    %eax,%ecx
f010184c:	89 fa                	mov    %edi,%edx
f010184e:	89 c8                	mov    %ecx,%eax
f0101850:	83 c4 10             	add    $0x10,%esp
f0101853:	5e                   	pop    %esi
f0101854:	5f                   	pop    %edi
f0101855:	5d                   	pop    %ebp
f0101856:	c3                   	ret    
f0101857:	90                   	nop
f0101858:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010185c:	89 f2                	mov    %esi,%edx
f010185e:	d3 e0                	shl    %cl,%eax
f0101860:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101863:	b8 20 00 00 00       	mov    $0x20,%eax
f0101868:	2b 45 f4             	sub    -0xc(%ebp),%eax
f010186b:	89 c1                	mov    %eax,%ecx
f010186d:	d3 ea                	shr    %cl,%edx
f010186f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101873:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101876:	d3 e6                	shl    %cl,%esi
f0101878:	89 c1                	mov    %eax,%ecx
f010187a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010187d:	89 fe                	mov    %edi,%esi
f010187f:	d3 ee                	shr    %cl,%esi
f0101881:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101885:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101888:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010188b:	d3 e7                	shl    %cl,%edi
f010188d:	89 c1                	mov    %eax,%ecx
f010188f:	d3 ea                	shr    %cl,%edx
f0101891:	09 d7                	or     %edx,%edi
f0101893:	89 f2                	mov    %esi,%edx
f0101895:	89 f8                	mov    %edi,%eax
f0101897:	f7 75 ec             	divl   -0x14(%ebp)
f010189a:	89 d6                	mov    %edx,%esi
f010189c:	89 c7                	mov    %eax,%edi
f010189e:	f7 65 e8             	mull   -0x18(%ebp)
f01018a1:	39 d6                	cmp    %edx,%esi
f01018a3:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01018a6:	72 30                	jb     f01018d8 <__udivdi3+0x118>
f01018a8:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01018ab:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f01018af:	d3 e2                	shl    %cl,%edx
f01018b1:	39 c2                	cmp    %eax,%edx
f01018b3:	73 05                	jae    f01018ba <__udivdi3+0xfa>
f01018b5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f01018b8:	74 1e                	je     f01018d8 <__udivdi3+0x118>
f01018ba:	89 f9                	mov    %edi,%ecx
f01018bc:	31 ff                	xor    %edi,%edi
f01018be:	e9 71 ff ff ff       	jmp    f0101834 <__udivdi3+0x74>
f01018c3:	90                   	nop
f01018c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018c8:	31 ff                	xor    %edi,%edi
f01018ca:	b9 01 00 00 00       	mov    $0x1,%ecx
f01018cf:	e9 60 ff ff ff       	jmp    f0101834 <__udivdi3+0x74>
f01018d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018d8:	8d 4f ff             	lea    -0x1(%edi),%ecx
f01018db:	31 ff                	xor    %edi,%edi
f01018dd:	89 c8                	mov    %ecx,%eax
f01018df:	89 fa                	mov    %edi,%edx
f01018e1:	83 c4 10             	add    $0x10,%esp
f01018e4:	5e                   	pop    %esi
f01018e5:	5f                   	pop    %edi
f01018e6:	5d                   	pop    %ebp
f01018e7:	c3                   	ret    
	...

f01018f0 <__umoddi3>:
f01018f0:	55                   	push   %ebp
f01018f1:	89 e5                	mov    %esp,%ebp
f01018f3:	57                   	push   %edi
f01018f4:	56                   	push   %esi
f01018f5:	83 ec 20             	sub    $0x20,%esp
f01018f8:	8b 55 14             	mov    0x14(%ebp),%edx
f01018fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01018fe:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101901:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101904:	85 d2                	test   %edx,%edx
f0101906:	89 c8                	mov    %ecx,%eax
f0101908:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f010190b:	75 13                	jne    f0101920 <__umoddi3+0x30>
f010190d:	39 f7                	cmp    %esi,%edi
f010190f:	76 3f                	jbe    f0101950 <__umoddi3+0x60>
f0101911:	89 f2                	mov    %esi,%edx
f0101913:	f7 f7                	div    %edi
f0101915:	89 d0                	mov    %edx,%eax
f0101917:	31 d2                	xor    %edx,%edx
f0101919:	83 c4 20             	add    $0x20,%esp
f010191c:	5e                   	pop    %esi
f010191d:	5f                   	pop    %edi
f010191e:	5d                   	pop    %ebp
f010191f:	c3                   	ret    
f0101920:	39 f2                	cmp    %esi,%edx
f0101922:	77 4c                	ja     f0101970 <__umoddi3+0x80>
f0101924:	0f bd ca             	bsr    %edx,%ecx
f0101927:	83 f1 1f             	xor    $0x1f,%ecx
f010192a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010192d:	75 51                	jne    f0101980 <__umoddi3+0x90>
f010192f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101932:	0f 87 e0 00 00 00    	ja     f0101a18 <__umoddi3+0x128>
f0101938:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010193b:	29 f8                	sub    %edi,%eax
f010193d:	19 d6                	sbb    %edx,%esi
f010193f:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101942:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101945:	89 f2                	mov    %esi,%edx
f0101947:	83 c4 20             	add    $0x20,%esp
f010194a:	5e                   	pop    %esi
f010194b:	5f                   	pop    %edi
f010194c:	5d                   	pop    %ebp
f010194d:	c3                   	ret    
f010194e:	66 90                	xchg   %ax,%ax
f0101950:	85 ff                	test   %edi,%edi
f0101952:	75 0b                	jne    f010195f <__umoddi3+0x6f>
f0101954:	b8 01 00 00 00       	mov    $0x1,%eax
f0101959:	31 d2                	xor    %edx,%edx
f010195b:	f7 f7                	div    %edi
f010195d:	89 c7                	mov    %eax,%edi
f010195f:	89 f0                	mov    %esi,%eax
f0101961:	31 d2                	xor    %edx,%edx
f0101963:	f7 f7                	div    %edi
f0101965:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101968:	f7 f7                	div    %edi
f010196a:	eb a9                	jmp    f0101915 <__umoddi3+0x25>
f010196c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101970:	89 c8                	mov    %ecx,%eax
f0101972:	89 f2                	mov    %esi,%edx
f0101974:	83 c4 20             	add    $0x20,%esp
f0101977:	5e                   	pop    %esi
f0101978:	5f                   	pop    %edi
f0101979:	5d                   	pop    %ebp
f010197a:	c3                   	ret    
f010197b:	90                   	nop
f010197c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101980:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101984:	d3 e2                	shl    %cl,%edx
f0101986:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101989:	ba 20 00 00 00       	mov    $0x20,%edx
f010198e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101991:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101994:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101998:	89 fa                	mov    %edi,%edx
f010199a:	d3 ea                	shr    %cl,%edx
f010199c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019a0:	0b 55 f4             	or     -0xc(%ebp),%edx
f01019a3:	d3 e7                	shl    %cl,%edi
f01019a5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01019a9:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01019ac:	89 f2                	mov    %esi,%edx
f01019ae:	89 7d e8             	mov    %edi,-0x18(%ebp)
f01019b1:	89 c7                	mov    %eax,%edi
f01019b3:	d3 ea                	shr    %cl,%edx
f01019b5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019b9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01019bc:	89 c2                	mov    %eax,%edx
f01019be:	d3 e6                	shl    %cl,%esi
f01019c0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01019c4:	d3 ea                	shr    %cl,%edx
f01019c6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019ca:	09 d6                	or     %edx,%esi
f01019cc:	89 f0                	mov    %esi,%eax
f01019ce:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01019d1:	d3 e7                	shl    %cl,%edi
f01019d3:	89 f2                	mov    %esi,%edx
f01019d5:	f7 75 f4             	divl   -0xc(%ebp)
f01019d8:	89 d6                	mov    %edx,%esi
f01019da:	f7 65 e8             	mull   -0x18(%ebp)
f01019dd:	39 d6                	cmp    %edx,%esi
f01019df:	72 2b                	jb     f0101a0c <__umoddi3+0x11c>
f01019e1:	39 c7                	cmp    %eax,%edi
f01019e3:	72 23                	jb     f0101a08 <__umoddi3+0x118>
f01019e5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019e9:	29 c7                	sub    %eax,%edi
f01019eb:	19 d6                	sbb    %edx,%esi
f01019ed:	89 f0                	mov    %esi,%eax
f01019ef:	89 f2                	mov    %esi,%edx
f01019f1:	d3 ef                	shr    %cl,%edi
f01019f3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01019f7:	d3 e0                	shl    %cl,%eax
f01019f9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019fd:	09 f8                	or     %edi,%eax
f01019ff:	d3 ea                	shr    %cl,%edx
f0101a01:	83 c4 20             	add    $0x20,%esp
f0101a04:	5e                   	pop    %esi
f0101a05:	5f                   	pop    %edi
f0101a06:	5d                   	pop    %ebp
f0101a07:	c3                   	ret    
f0101a08:	39 d6                	cmp    %edx,%esi
f0101a0a:	75 d9                	jne    f01019e5 <__umoddi3+0xf5>
f0101a0c:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101a0f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f0101a12:	eb d1                	jmp    f01019e5 <__umoddi3+0xf5>
f0101a14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	39 f2                	cmp    %esi,%edx
f0101a1a:	0f 82 18 ff ff ff    	jb     f0101938 <__umoddi3+0x48>
f0101a20:	e9 1d ff ff ff       	jmp    f0101942 <__umoddi3+0x52>
