
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f0100058:	c7 04 24 c0 1f 10 f0 	movl   $0xf0101fc0,(%esp)
f010005f:	e8 bf 0c 00 00       	call   f0100d23 <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 7d 0c 00 00       	call   f0100cf0 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 e6 20 10 f0 	movl   $0xf01020e6,(%esp)
f010007a:	e8 a4 0c 00 00       	call   f0100d23 <cprintf>
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
f0100090:	83 3d 00 33 11 f0 00 	cmpl   $0x0,0xf0113300
f0100097:	75 3d                	jne    f01000d6 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100099:	89 35 00 33 11 f0    	mov    %esi,0xf0113300

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
f01000b2:	c7 04 24 da 1f 10 f0 	movl   $0xf0101fda,(%esp)
f01000b9:	e8 65 0c 00 00       	call   f0100d23 <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 26 0c 00 00       	call   f0100cf0 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 e6 20 10 f0 	movl   $0xf01020e6,(%esp)
f01000d1:	e8 4d 0c 00 00       	call   f0100d23 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 0b 09 00 00       	call   f01009ed <monitor>
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
f01000f2:	c7 04 24 f2 1f 10 f0 	movl   $0xf0101ff2,(%esp)
f01000f9:	e8 25 0c 00 00       	call   f0100d23 <cprintf>
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
f0100126:	e8 c5 0a 00 00       	call   f0100bf0 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010012b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012f:	c7 04 24 0e 20 10 f0 	movl   $0xf010200e,(%esp)
f0100136:	e8 e8 0b 00 00       	call   f0100d23 <cprintf>
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
f0100144:	57                   	push   %edi
f0100145:	53                   	push   %ebx
f0100146:	81 ec 20 01 00 00    	sub    $0x120,%esp
	extern char edata[], end[];
    // Lab1 only
    char chnum1 = 0, chnum2 = 0, ntest[256] = {};
f010014c:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
f0100150:	c6 45 f6 00          	movb   $0x0,-0xa(%ebp)
f0100154:	ba 00 01 00 00       	mov    $0x100,%edx
f0100159:	b8 00 00 00 00       	mov    $0x0,%eax
f010015e:	8d bd f6 fe ff ff    	lea    -0x10a(%ebp),%edi
f0100164:	66 ab                	stos   %ax,%es:(%edi)
f0100166:	83 ea 02             	sub    $0x2,%edx
f0100169:	89 d1                	mov    %edx,%ecx
f010016b:	c1 e9 02             	shr    $0x2,%ecx
f010016e:	f3 ab                	rep stos %eax,%es:(%edi)
f0100170:	f6 c2 02             	test   $0x2,%dl
f0100173:	74 02                	je     f0100177 <i386_init+0x36>
f0100175:	66 ab                	stos   %ax,%es:(%edi)
f0100177:	83 e2 01             	and    $0x1,%edx
f010017a:	85 d2                	test   %edx,%edx
f010017c:	74 01                	je     f010017f <i386_init+0x3e>
f010017e:	aa                   	stos   %al,%es:(%edi)

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010017f:	b8 60 39 11 f0       	mov    $0xf0113960,%eax
f0100184:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100189:	89 44 24 08          	mov    %eax,0x8(%esp)
f010018d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100194:	00 
f0100195:	c7 04 24 00 33 11 f0 	movl   $0xf0113300,(%esp)
f010019c:	e8 45 19 00 00       	call   f0101ae6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01001a1:	e8 f4 03 00 00       	call   f010059a <cons_init>

	cprintf("6828 decimal is %o octal!%n\n%n", 6828, &chnum1, &chnum2);
f01001a6:	8d 45 f6             	lea    -0xa(%ebp),%eax
f01001a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001ad:	8d 7d f7             	lea    -0x9(%ebp),%edi
f01001b0:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01001b4:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01001bb:	00 
f01001bc:	c7 04 24 70 20 10 f0 	movl   $0xf0102070,(%esp)
f01001c3:	e8 5b 0b 00 00       	call   f0100d23 <cprintf>
	cprintf("pading space in the right to number 22: %-8d.\n", 22);
f01001c8:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
f01001cf:	00 
f01001d0:	c7 04 24 90 20 10 f0 	movl   $0xf0102090,(%esp)
f01001d7:	e8 47 0b 00 00       	call   f0100d23 <cprintf>
	cprintf("chnum1: %d chnum2: %d\n", chnum1, chnum2);
f01001dc:	0f be 45 f6          	movsbl -0xa(%ebp),%eax
f01001e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01001e4:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
f01001e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01001ec:	c7 04 24 29 20 10 f0 	movl   $0xf0102029,(%esp)
f01001f3:	e8 2b 0b 00 00       	call   f0100d23 <cprintf>
	cprintf("%n", NULL);
f01001f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001ff:	00 
f0100200:	c7 04 24 42 20 10 f0 	movl   $0xf0102042,(%esp)
f0100207:	e8 17 0b 00 00       	call   f0100d23 <cprintf>
	memset(ntest, 0xd, sizeof(ntest) - 1);
f010020c:	c7 44 24 08 ff 00 00 	movl   $0xff,0x8(%esp)
f0100213:	00 
f0100214:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
f010021b:	00 
f010021c:	8d 9d f6 fe ff ff    	lea    -0x10a(%ebp),%ebx
f0100222:	89 1c 24             	mov    %ebx,(%esp)
f0100225:	e8 bc 18 00 00       	call   f0101ae6 <memset>
	cprintf("%s%n", ntest, &chnum1); 
f010022a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010022e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100232:	c7 04 24 40 20 10 f0 	movl   $0xf0102040,(%esp)
f0100239:	e8 e5 0a 00 00       	call   f0100d23 <cprintf>
	cprintf("chnum1: %d\n", chnum1);
f010023e:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
f0100242:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100246:	c7 04 24 45 20 10 f0 	movl   $0xf0102045,(%esp)
f010024d:	e8 d1 0a 00 00       	call   f0100d23 <cprintf>
	cprintf("show me the sign: %+d, %+d\n", 1024, -1024);
f0100252:	c7 44 24 08 00 fc ff 	movl   $0xfffffc00,0x8(%esp)
f0100259:	ff 
f010025a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
f0100261:	00 
f0100262:	c7 04 24 51 20 10 f0 	movl   $0xf0102051,(%esp)
f0100269:	e8 b5 0a 00 00       	call   f0100d23 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f010026e:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100275:	e8 6a fe ff ff       	call   f01000e4 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010027a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100281:	e8 67 07 00 00       	call   f01009ed <monitor>
f0100286:	eb f2                	jmp    f010027a <i386_init+0x139>
	...

f0100290 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100293:	ba 84 00 00 00       	mov    $0x84,%edx
f0100298:	ec                   	in     (%dx),%al
f0100299:	ec                   	in     (%dx),%al
f010029a:	ec                   	in     (%dx),%al
f010029b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010029c:	5d                   	pop    %ebp
f010029d:	c3                   	ret    

f010029e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002a6:	ec                   	in     (%dx),%al
f01002a7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ae:	f6 c2 01             	test   $0x1,%dl
f01002b1:	74 09                	je     f01002bc <serial_proc_data+0x1e>
f01002b3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002b8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002b9:	0f b6 c0             	movzbl %al,%eax
}
f01002bc:	5d                   	pop    %ebp
f01002bd:	c3                   	ret    

f01002be <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002be:	55                   	push   %ebp
f01002bf:	89 e5                	mov    %esp,%ebp
f01002c1:	57                   	push   %edi
f01002c2:	56                   	push   %esi
f01002c3:	53                   	push   %ebx
f01002c4:	83 ec 0c             	sub    $0xc,%esp
f01002c7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01002c9:	bb 44 35 11 f0       	mov    $0xf0113544,%ebx
f01002ce:	bf 40 33 11 f0       	mov    $0xf0113340,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d3:	eb 1e                	jmp    f01002f3 <cons_intr+0x35>
		if (c == 0)
f01002d5:	85 c0                	test   %eax,%eax
f01002d7:	74 1a                	je     f01002f3 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002d9:	8b 13                	mov    (%ebx),%edx
f01002db:	88 04 17             	mov    %al,(%edi,%edx,1)
f01002de:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01002e1:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01002e6:	0f 94 c2             	sete   %dl
f01002e9:	0f b6 d2             	movzbl %dl,%edx
f01002ec:	83 ea 01             	sub    $0x1,%edx
f01002ef:	21 d0                	and    %edx,%eax
f01002f1:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002f3:	ff d6                	call   *%esi
f01002f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002f8:	75 db                	jne    f01002d5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002fa:	83 c4 0c             	add    $0xc,%esp
f01002fd:	5b                   	pop    %ebx
f01002fe:	5e                   	pop    %esi
f01002ff:	5f                   	pop    %edi
f0100300:	5d                   	pop    %ebp
f0100301:	c3                   	ret    

f0100302 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100302:	55                   	push   %ebp
f0100303:	89 e5                	mov    %esp,%ebp
f0100305:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100308:	b8 8a 06 10 f0       	mov    $0xf010068a,%eax
f010030d:	e8 ac ff ff ff       	call   f01002be <cons_intr>
}
f0100312:	c9                   	leave  
f0100313:	c3                   	ret    

f0100314 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100314:	55                   	push   %ebp
f0100315:	89 e5                	mov    %esp,%ebp
f0100317:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010031a:	83 3d 24 33 11 f0 00 	cmpl   $0x0,0xf0113324
f0100321:	74 0a                	je     f010032d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100323:	b8 9e 02 10 f0       	mov    $0xf010029e,%eax
f0100328:	e8 91 ff ff ff       	call   f01002be <cons_intr>
}
f010032d:	c9                   	leave  
f010032e:	c3                   	ret    

f010032f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010032f:	55                   	push   %ebp
f0100330:	89 e5                	mov    %esp,%ebp
f0100332:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100335:	e8 da ff ff ff       	call   f0100314 <serial_intr>
	kbd_intr();
f010033a:	e8 c3 ff ff ff       	call   f0100302 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010033f:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
f0100345:	b8 00 00 00 00       	mov    $0x0,%eax
f010034a:	3b 15 44 35 11 f0    	cmp    0xf0113544,%edx
f0100350:	74 21                	je     f0100373 <cons_getc+0x44>
		c = cons.buf[cons.rpos++];
f0100352:	0f b6 82 40 33 11 f0 	movzbl -0xfeeccc0(%edx),%eax
f0100359:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010035c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100362:	0f 94 c1             	sete   %cl
f0100365:	0f b6 c9             	movzbl %cl,%ecx
f0100368:	83 e9 01             	sub    $0x1,%ecx
f010036b:	21 ca                	and    %ecx,%edx
f010036d:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
		return c;
	}
	return 0;
}
f0100373:	c9                   	leave  
f0100374:	c3                   	ret    

f0100375 <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f0100375:	55                   	push   %ebp
f0100376:	89 e5                	mov    %esp,%ebp
f0100378:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010037b:	e8 af ff ff ff       	call   f010032f <cons_getc>
f0100380:	85 c0                	test   %eax,%eax
f0100382:	74 f7                	je     f010037b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100384:	c9                   	leave  
f0100385:	c3                   	ret    

f0100386 <iscons>:

int
iscons(int fdnum)
{
f0100386:	55                   	push   %ebp
f0100387:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100389:	b8 01 00 00 00       	mov    $0x1,%eax
f010038e:	5d                   	pop    %ebp
f010038f:	c3                   	ret    

f0100390 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100390:	55                   	push   %ebp
f0100391:	89 e5                	mov    %esp,%ebp
f0100393:	57                   	push   %edi
f0100394:	56                   	push   %esi
f0100395:	53                   	push   %ebx
f0100396:	83 ec 2c             	sub    $0x2c,%esp
f0100399:	89 c7                	mov    %eax,%edi
f010039b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01003a0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01003a1:	a8 20                	test   $0x20,%al
f01003a3:	75 21                	jne    f01003c6 <cons_putc+0x36>
f01003a5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003aa:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01003af:	e8 dc fe ff ff       	call   f0100290 <delay>
f01003b4:	89 f2                	mov    %esi,%edx
f01003b6:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01003b7:	a8 20                	test   $0x20,%al
f01003b9:	75 0b                	jne    f01003c6 <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003bb:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01003be:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01003c4:	75 e9                	jne    f01003af <cons_putc+0x1f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01003c6:	89 fa                	mov    %edi,%edx
f01003c8:	89 f8                	mov    %edi,%eax
f01003ca:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003d3:	b2 79                	mov    $0x79,%dl
f01003d5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003d6:	84 c0                	test   %al,%al
f01003d8:	78 21                	js     f01003fb <cons_putc+0x6b>
f01003da:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003df:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01003e4:	e8 a7 fe ff ff       	call   f0100290 <delay>
f01003e9:	89 f2                	mov    %esi,%edx
f01003eb:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003ec:	84 c0                	test   %al,%al
f01003ee:	78 0b                	js     f01003fb <cons_putc+0x6b>
f01003f0:	83 c3 01             	add    $0x1,%ebx
f01003f3:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01003f9:	75 e9                	jne    f01003e4 <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003fb:	ba 78 03 00 00       	mov    $0x378,%edx
f0100400:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100404:	ee                   	out    %al,(%dx)
f0100405:	b2 7a                	mov    $0x7a,%dl
f0100407:	b8 0d 00 00 00       	mov    $0xd,%eax
f010040c:	ee                   	out    %al,(%dx)
f010040d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100412:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100413:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100419:	75 06                	jne    f0100421 <cons_putc+0x91>
		c |= 0x0700;
f010041b:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100421:	89 f8                	mov    %edi,%eax
f0100423:	25 ff 00 00 00       	and    $0xff,%eax
f0100428:	83 f8 09             	cmp    $0x9,%eax
f010042b:	0f 84 83 00 00 00    	je     f01004b4 <cons_putc+0x124>
f0100431:	83 f8 09             	cmp    $0x9,%eax
f0100434:	7f 0c                	jg     f0100442 <cons_putc+0xb2>
f0100436:	83 f8 08             	cmp    $0x8,%eax
f0100439:	0f 85 a9 00 00 00    	jne    f01004e8 <cons_putc+0x158>
f010043f:	90                   	nop
f0100440:	eb 18                	jmp    f010045a <cons_putc+0xca>
f0100442:	83 f8 0a             	cmp    $0xa,%eax
f0100445:	8d 76 00             	lea    0x0(%esi),%esi
f0100448:	74 40                	je     f010048a <cons_putc+0xfa>
f010044a:	83 f8 0d             	cmp    $0xd,%eax
f010044d:	8d 76 00             	lea    0x0(%esi),%esi
f0100450:	0f 85 92 00 00 00    	jne    f01004e8 <cons_putc+0x158>
f0100456:	66 90                	xchg   %ax,%ax
f0100458:	eb 38                	jmp    f0100492 <cons_putc+0x102>
	case '\b':
		if (crt_pos > 0) {
f010045a:	0f b7 05 30 33 11 f0 	movzwl 0xf0113330,%eax
f0100461:	66 85 c0             	test   %ax,%ax
f0100464:	0f 84 e8 00 00 00    	je     f0100552 <cons_putc+0x1c2>
			crt_pos--;
f010046a:	83 e8 01             	sub    $0x1,%eax
f010046d:	66 a3 30 33 11 f0    	mov    %ax,0xf0113330
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100473:	0f b7 c0             	movzwl %ax,%eax
f0100476:	66 81 e7 00 ff       	and    $0xff00,%di
f010047b:	83 cf 20             	or     $0x20,%edi
f010047e:	8b 15 2c 33 11 f0    	mov    0xf011332c,%edx
f0100484:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100488:	eb 7b                	jmp    f0100505 <cons_putc+0x175>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010048a:	66 83 05 30 33 11 f0 	addw   $0x50,0xf0113330
f0100491:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100492:	0f b7 05 30 33 11 f0 	movzwl 0xf0113330,%eax
f0100499:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010049f:	c1 e8 10             	shr    $0x10,%eax
f01004a2:	66 c1 e8 06          	shr    $0x6,%ax
f01004a6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004a9:	c1 e0 04             	shl    $0x4,%eax
f01004ac:	66 a3 30 33 11 f0    	mov    %ax,0xf0113330
f01004b2:	eb 51                	jmp    f0100505 <cons_putc+0x175>
		break;
	case '\t':
		cons_putc(' ');
f01004b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01004b9:	e8 d2 fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004be:	b8 20 00 00 00       	mov    $0x20,%eax
f01004c3:	e8 c8 fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004cd:	e8 be fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d7:	e8 b4 fe ff ff       	call   f0100390 <cons_putc>
		cons_putc(' ');
f01004dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e1:	e8 aa fe ff ff       	call   f0100390 <cons_putc>
f01004e6:	eb 1d                	jmp    f0100505 <cons_putc+0x175>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01004e8:	0f b7 05 30 33 11 f0 	movzwl 0xf0113330,%eax
f01004ef:	0f b7 c8             	movzwl %ax,%ecx
f01004f2:	8b 15 2c 33 11 f0    	mov    0xf011332c,%edx
f01004f8:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01004fc:	83 c0 01             	add    $0x1,%eax
f01004ff:	66 a3 30 33 11 f0    	mov    %ax,0xf0113330
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100505:	66 81 3d 30 33 11 f0 	cmpw   $0x7cf,0xf0113330
f010050c:	cf 07 
f010050e:	76 42                	jbe    f0100552 <cons_putc+0x1c2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100510:	a1 2c 33 11 f0       	mov    0xf011332c,%eax
f0100515:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010051c:	00 
f010051d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100523:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100527:	89 04 24             	mov    %eax,(%esp)
f010052a:	e8 16 16 00 00       	call   f0101b45 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010052f:	8b 15 2c 33 11 f0    	mov    0xf011332c,%edx
f0100535:	b8 80 07 00 00       	mov    $0x780,%eax
f010053a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100540:	83 c0 01             	add    $0x1,%eax
f0100543:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100548:	75 f0                	jne    f010053a <cons_putc+0x1aa>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010054a:	66 83 2d 30 33 11 f0 	subw   $0x50,0xf0113330
f0100551:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100552:	8b 0d 28 33 11 f0    	mov    0xf0113328,%ecx
f0100558:	89 cb                	mov    %ecx,%ebx
f010055a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010055f:	89 ca                	mov    %ecx,%edx
f0100561:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100562:	0f b7 35 30 33 11 f0 	movzwl 0xf0113330,%esi
f0100569:	83 c1 01             	add    $0x1,%ecx
f010056c:	89 f0                	mov    %esi,%eax
f010056e:	66 c1 e8 08          	shr    $0x8,%ax
f0100572:	89 ca                	mov    %ecx,%edx
f0100574:	ee                   	out    %al,(%dx)
f0100575:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057a:	89 da                	mov    %ebx,%edx
f010057c:	ee                   	out    %al,(%dx)
f010057d:	89 f0                	mov    %esi,%eax
f010057f:	89 ca                	mov    %ecx,%edx
f0100581:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100582:	83 c4 2c             	add    $0x2c,%esp
f0100585:	5b                   	pop    %ebx
f0100586:	5e                   	pop    %esi
f0100587:	5f                   	pop    %edi
f0100588:	5d                   	pop    %ebp
f0100589:	c3                   	ret    

f010058a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010058a:	55                   	push   %ebp
f010058b:	89 e5                	mov    %esp,%ebp
f010058d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100590:	8b 45 08             	mov    0x8(%ebp),%eax
f0100593:	e8 f8 fd ff ff       	call   f0100390 <cons_putc>
}
f0100598:	c9                   	leave  
f0100599:	c3                   	ret    

f010059a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	57                   	push   %edi
f010059e:	56                   	push   %esi
f010059f:	53                   	push   %ebx
f01005a0:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01005a3:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01005a8:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01005ab:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01005b0:	0f b7 00             	movzwl (%eax),%eax
f01005b3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005b7:	74 11                	je     f01005ca <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005b9:	c7 05 28 33 11 f0 b4 	movl   $0x3b4,0xf0113328
f01005c0:	03 00 00 
f01005c3:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005c8:	eb 16                	jmp    f01005e0 <cons_init+0x46>
	} else {
		*cp = was;
f01005ca:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005d1:	c7 05 28 33 11 f0 d4 	movl   $0x3d4,0xf0113328
f01005d8:	03 00 00 
f01005db:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005e0:	8b 0d 28 33 11 f0    	mov    0xf0113328,%ecx
f01005e6:	89 cb                	mov    %ecx,%ebx
f01005e8:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ed:	89 ca                	mov    %ecx,%edx
f01005ef:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f0:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f3:	89 ca                	mov    %ecx,%edx
f01005f5:	ec                   	in     (%dx),%al
f01005f6:	0f b6 f8             	movzbl %al,%edi
f01005f9:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005fc:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100601:	89 da                	mov    %ebx,%edx
f0100603:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100604:	89 ca                	mov    %ecx,%edx
f0100606:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100607:	89 35 2c 33 11 f0    	mov    %esi,0xf011332c
	crt_pos = pos;
f010060d:	0f b6 c8             	movzbl %al,%ecx
f0100610:	09 cf                	or     %ecx,%edi
f0100612:	66 89 3d 30 33 11 f0 	mov    %di,0xf0113330
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100619:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010061e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100623:	89 da                	mov    %ebx,%edx
f0100625:	ee                   	out    %al,(%dx)
f0100626:	b2 fb                	mov    $0xfb,%dl
f0100628:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010062d:	ee                   	out    %al,(%dx)
f010062e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100633:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100638:	89 ca                	mov    %ecx,%edx
f010063a:	ee                   	out    %al,(%dx)
f010063b:	b2 f9                	mov    $0xf9,%dl
f010063d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100642:	ee                   	out    %al,(%dx)
f0100643:	b2 fb                	mov    $0xfb,%dl
f0100645:	b8 03 00 00 00       	mov    $0x3,%eax
f010064a:	ee                   	out    %al,(%dx)
f010064b:	b2 fc                	mov    $0xfc,%dl
f010064d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b2 f9                	mov    $0xf9,%dl
f0100655:	b8 01 00 00 00       	mov    $0x1,%eax
f010065a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010065b:	b2 fd                	mov    $0xfd,%dl
f010065d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010065e:	3c ff                	cmp    $0xff,%al
f0100660:	0f 95 c0             	setne  %al
f0100663:	0f b6 f0             	movzbl %al,%esi
f0100666:	89 35 24 33 11 f0    	mov    %esi,0xf0113324
f010066c:	89 da                	mov    %ebx,%edx
f010066e:	ec                   	in     (%dx),%al
f010066f:	89 ca                	mov    %ecx,%edx
f0100671:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100672:	85 f6                	test   %esi,%esi
f0100674:	75 0c                	jne    f0100682 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100676:	c7 04 24 bf 20 10 f0 	movl   $0xf01020bf,(%esp)
f010067d:	e8 a1 06 00 00       	call   f0100d23 <cprintf>
}
f0100682:	83 c4 1c             	add    $0x1c,%esp
f0100685:	5b                   	pop    %ebx
f0100686:	5e                   	pop    %esi
f0100687:	5f                   	pop    %edi
f0100688:	5d                   	pop    %ebp
f0100689:	c3                   	ret    

f010068a <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010068a:	55                   	push   %ebp
f010068b:	89 e5                	mov    %esp,%ebp
f010068d:	53                   	push   %ebx
f010068e:	83 ec 14             	sub    $0x14,%esp
f0100691:	ba 64 00 00 00       	mov    $0x64,%edx
f0100696:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100697:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010069c:	a8 01                	test   $0x1,%al
f010069e:	0f 84 d9 00 00 00    	je     f010077d <kbd_proc_data+0xf3>
f01006a4:	b2 60                	mov    $0x60,%dl
f01006a6:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01006a7:	3c e0                	cmp    $0xe0,%al
f01006a9:	75 11                	jne    f01006bc <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01006ab:	83 0d 20 33 11 f0 40 	orl    $0x40,0xf0113320
f01006b2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01006b7:	e9 c1 00 00 00       	jmp    f010077d <kbd_proc_data+0xf3>
	} else if (data & 0x80) {
f01006bc:	84 c0                	test   %al,%al
f01006be:	79 32                	jns    f01006f2 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01006c0:	8b 15 20 33 11 f0    	mov    0xf0113320,%edx
f01006c6:	f6 c2 40             	test   $0x40,%dl
f01006c9:	75 03                	jne    f01006ce <kbd_proc_data+0x44>
f01006cb:	83 e0 7f             	and    $0x7f,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01006ce:	0f b6 c0             	movzbl %al,%eax
f01006d1:	0f b6 80 00 21 10 f0 	movzbl -0xfefdf00(%eax),%eax
f01006d8:	83 c8 40             	or     $0x40,%eax
f01006db:	0f b6 c0             	movzbl %al,%eax
f01006de:	f7 d0                	not    %eax
f01006e0:	21 c2                	and    %eax,%edx
f01006e2:	89 15 20 33 11 f0    	mov    %edx,0xf0113320
f01006e8:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01006ed:	e9 8b 00 00 00       	jmp    f010077d <kbd_proc_data+0xf3>
	} else if (shift & E0ESC) {
f01006f2:	8b 15 20 33 11 f0    	mov    0xf0113320,%edx
f01006f8:	f6 c2 40             	test   $0x40,%dl
f01006fb:	74 0c                	je     f0100709 <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01006fd:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100700:	83 e2 bf             	and    $0xffffffbf,%edx
f0100703:	89 15 20 33 11 f0    	mov    %edx,0xf0113320
	}

	shift |= shiftcode[data];
f0100709:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010070c:	0f b6 90 00 21 10 f0 	movzbl -0xfefdf00(%eax),%edx
f0100713:	0b 15 20 33 11 f0    	or     0xf0113320,%edx
f0100719:	0f b6 88 00 22 10 f0 	movzbl -0xfefde00(%eax),%ecx
f0100720:	31 ca                	xor    %ecx,%edx
f0100722:	89 15 20 33 11 f0    	mov    %edx,0xf0113320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100728:	89 d1                	mov    %edx,%ecx
f010072a:	83 e1 03             	and    $0x3,%ecx
f010072d:	8b 0c 8d 00 23 10 f0 	mov    -0xfefdd00(,%ecx,4),%ecx
f0100734:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f0100738:	f6 c2 08             	test   $0x8,%dl
f010073b:	74 1a                	je     f0100757 <kbd_proc_data+0xcd>
		if ('a' <= c && c <= 'z')
f010073d:	89 d9                	mov    %ebx,%ecx
f010073f:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100742:	83 f8 19             	cmp    $0x19,%eax
f0100745:	77 05                	ja     f010074c <kbd_proc_data+0xc2>
			c += 'A' - 'a';
f0100747:	83 eb 20             	sub    $0x20,%ebx
f010074a:	eb 0b                	jmp    f0100757 <kbd_proc_data+0xcd>
		else if ('A' <= c && c <= 'Z')
f010074c:	83 e9 41             	sub    $0x41,%ecx
f010074f:	83 f9 19             	cmp    $0x19,%ecx
f0100752:	77 03                	ja     f0100757 <kbd_proc_data+0xcd>
			c += 'a' - 'A';
f0100754:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100757:	f7 d2                	not    %edx
f0100759:	f6 c2 06             	test   $0x6,%dl
f010075c:	75 1f                	jne    f010077d <kbd_proc_data+0xf3>
f010075e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100764:	75 17                	jne    f010077d <kbd_proc_data+0xf3>
		cprintf("Rebooting!\n");
f0100766:	c7 04 24 dc 20 10 f0 	movl   $0xf01020dc,(%esp)
f010076d:	e8 b1 05 00 00       	call   f0100d23 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100772:	ba 92 00 00 00       	mov    $0x92,%edx
f0100777:	b8 03 00 00 00       	mov    $0x3,%eax
f010077c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010077d:	89 d8                	mov    %ebx,%eax
f010077f:	83 c4 14             	add    $0x14,%esp
f0100782:	5b                   	pop    %ebx
f0100783:	5d                   	pop    %ebp
f0100784:	c3                   	ret    
	...

f0100790 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100790:	55                   	push   %ebp
f0100791:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100793:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100796:	5d                   	pop    %ebp
f0100797:	c3                   	ret    

f0100798 <start_overflow>:
    cprintf("Overflow success\n");
}

void
start_overflow(void)
{
f0100798:	55                   	push   %ebp
f0100799:	89 e5                	mov    %esp,%ebp
f010079b:	57                   	push   %edi
f010079c:	56                   	push   %esi
f010079d:	53                   	push   %ebx
f010079e:	81 ec 2c 01 00 00    	sub    $0x12c,%esp
    // you augmented in the "Exercise 9" to do this job.

    // hint: You can use the read_pretaddr function to retrieve 
    //       the pointer to the function call return address;

    char str[256] = {};
f01007a4:	8d bd e8 fe ff ff    	lea    -0x118(%ebp),%edi
f01007aa:	b9 40 00 00 00       	mov    $0x40,%ecx
f01007af:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b4:	f3 ab                	rep stos %eax,%es:(%edi)
    int nstr = 0;
    char *pret_addr;

	// Your code here.
	// replace 'ret to overflow_me' to 'ret to do_overflow' 
	pret_addr = (char*)read_pretaddr(); // get eip pointer
f01007b6:	8d 75 04             	lea    0x4(%ebp),%esi
	int i = 0;
	for (;i < 256; i++) {
		str[i] = 'h';
f01007b9:	c6 85 e8 fe ff ff 68 	movb   $0x68,-0x118(%ebp)
f01007c0:	8d 95 e8 fe ff ff    	lea    -0x118(%ebp),%edx
f01007c6:	eb 0c                	jmp    f01007d4 <start_overflow+0x3c>
f01007c8:	c6 04 02 68          	movb   $0x68,(%edx,%eax,1)
		if (i%2)
f01007cc:	a8 01                	test   $0x1,%al
f01007ce:	74 04                	je     f01007d4 <start_overflow+0x3c>
			str[i] = 'a';
f01007d0:	c6 04 02 61          	movb   $0x61,(%edx,%eax,1)

	// Your code here.
	// replace 'ret to overflow_me' to 'ret to do_overflow' 
	pret_addr = (char*)read_pretaddr(); // get eip pointer
	int i = 0;
	for (;i < 256; i++) {
f01007d4:	83 c0 01             	add    $0x1,%eax
f01007d7:	3d 00 01 00 00       	cmp    $0x100,%eax
f01007dc:	75 ea                	jne    f01007c8 <start_overflow+0x30>
		if (i%2)
			str[i] = 'a';
	}
	void (*do_overflow_t)();
	do_overflow_t = do_overflow;
	uint32_t ret_addr = (uint32_t)do_overflow_t+3; // ignore stack asm code
f01007de:	bf e4 08 10 f0       	mov    $0xf01008e4,%edi
	
	uint32_t ret_byte_0 = ret_addr & 0xff;
f01007e3:	89 f8                	mov    %edi,%eax
f01007e5:	25 ff 00 00 00       	and    $0xff,%eax
f01007ea:	89 85 dc fe ff ff    	mov    %eax,-0x124(%ebp)
	uint32_t ret_byte_1 = (ret_addr >> 8) & 0xff;
f01007f0:	89 f8                	mov    %edi,%eax
f01007f2:	0f b6 c4             	movzbl %ah,%eax
f01007f5:	89 85 e0 fe ff ff    	mov    %eax,-0x120(%ebp)
	uint32_t ret_byte_2 = (ret_addr >> 16) & 0xff;
f01007fb:	89 f8                	mov    %edi,%eax
f01007fd:	c1 e8 10             	shr    $0x10,%eax
f0100800:	25 ff 00 00 00       	and    $0xff,%eax
f0100805:	89 85 e4 fe ff ff    	mov    %eax,-0x11c(%ebp)
	uint32_t ret_byte_3 = (ret_addr >> 24) & 0xff;
	str[ret_byte_0] = '\0';
f010080b:	8b 85 dc fe ff ff    	mov    -0x124(%ebp),%eax
f0100811:	c6 84 05 e8 fe ff ff 	movb   $0x0,-0x118(%ebp,%eax,1)
f0100818:	00 
	cprintf("%s%n\n", str, pret_addr);
f0100819:	89 74 24 08          	mov    %esi,0x8(%esp)
f010081d:	8d 9d e8 fe ff ff    	lea    -0x118(%ebp),%ebx
f0100823:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100827:	c7 04 24 10 23 10 f0 	movl   $0xf0102310,(%esp)
f010082e:	e8 f0 04 00 00       	call   f0100d23 <cprintf>
	str[ret_byte_0] = 'h';
f0100833:	8b 85 dc fe ff ff    	mov    -0x124(%ebp),%eax
f0100839:	c6 84 05 e8 fe ff ff 	movb   $0x68,-0x118(%ebp,%eax,1)
f0100840:	68 
	str[ret_byte_1] = '\0';
f0100841:	8b 85 e0 fe ff ff    	mov    -0x120(%ebp),%eax
f0100847:	c6 84 05 e8 fe ff ff 	movb   $0x0,-0x118(%ebp,%eax,1)
f010084e:	00 
	cprintf("%s%n\n", str, pret_addr+1);
f010084f:	8d 46 01             	lea    0x1(%esi),%eax
f0100852:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100856:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010085a:	c7 04 24 10 23 10 f0 	movl   $0xf0102310,(%esp)
f0100861:	e8 bd 04 00 00       	call   f0100d23 <cprintf>
	str[ret_byte_1] = 'h';
f0100866:	8b 85 e0 fe ff ff    	mov    -0x120(%ebp),%eax
f010086c:	c6 84 05 e8 fe ff ff 	movb   $0x68,-0x118(%ebp,%eax,1)
f0100873:	68 
	str[ret_byte_2] = '\0';
f0100874:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
f010087a:	c6 84 05 e8 fe ff ff 	movb   $0x0,-0x118(%ebp,%eax,1)
f0100881:	00 
	cprintf("%s%n\n", str, pret_addr+2);
f0100882:	8d 46 02             	lea    0x2(%esi),%eax
f0100885:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100889:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010088d:	c7 04 24 10 23 10 f0 	movl   $0xf0102310,(%esp)
f0100894:	e8 8a 04 00 00       	call   f0100d23 <cprintf>
	str[ret_byte_2] = 'h';
f0100899:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
f010089f:	c6 84 05 e8 fe ff ff 	movb   $0x68,-0x118(%ebp,%eax,1)
f01008a6:	68 
	str[ret_byte_3] = '\0';
f01008a7:	c1 ef 18             	shr    $0x18,%edi
f01008aa:	c6 84 3d e8 fe ff ff 	movb   $0x0,-0x118(%ebp,%edi,1)
f01008b1:	00 
	cprintf("%s%n\n", str, pret_addr+3);
f01008b2:	83 c6 03             	add    $0x3,%esi
f01008b5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01008b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008bd:	c7 04 24 10 23 10 f0 	movl   $0xf0102310,(%esp)
f01008c4:	e8 5a 04 00 00       	call   f0100d23 <cprintf>
}
f01008c9:	81 c4 2c 01 00 00    	add    $0x12c,%esp
f01008cf:	5b                   	pop    %ebx
f01008d0:	5e                   	pop    %esi
f01008d1:	5f                   	pop    %edi
f01008d2:	5d                   	pop    %ebp
f01008d3:	c3                   	ret    

f01008d4 <overflow_me>:

void
overflow_me(void)
{
f01008d4:	55                   	push   %ebp
f01008d5:	89 e5                	mov    %esp,%ebp
f01008d7:	83 ec 08             	sub    $0x8,%esp
        start_overflow();
f01008da:	e8 b9 fe ff ff       	call   f0100798 <start_overflow>
}
f01008df:	c9                   	leave  
f01008e0:	c3                   	ret    

f01008e1 <do_overflow>:
    return pretaddr;
}

void
do_overflow(void)
{
f01008e1:	55                   	push   %ebp
f01008e2:	89 e5                	mov    %esp,%ebp
f01008e4:	83 ec 18             	sub    $0x18,%esp
    cprintf("Overflow success\n");
f01008e7:	c7 04 24 16 23 10 f0 	movl   $0xf0102316,(%esp)
f01008ee:	e8 30 04 00 00       	call   f0100d23 <cprintf>
}
f01008f3:	c9                   	leave  
f01008f4:	c3                   	ret    

f01008f5 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01008f5:	55                   	push   %ebp
f01008f6:	89 e5                	mov    %esp,%ebp
f01008f8:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01008fb:	c7 04 24 28 23 10 f0 	movl   $0xf0102328,(%esp)
f0100902:	e8 1c 04 00 00       	call   f0100d23 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100907:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010090e:	00 
f010090f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100916:	f0 
f0100917:	c7 04 24 40 24 10 f0 	movl   $0xf0102440,(%esp)
f010091e:	e8 00 04 00 00       	call   f0100d23 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100923:	c7 44 24 08 b5 1f 10 	movl   $0x101fb5,0x8(%esp)
f010092a:	00 
f010092b:	c7 44 24 04 b5 1f 10 	movl   $0xf0101fb5,0x4(%esp)
f0100932:	f0 
f0100933:	c7 04 24 64 24 10 f0 	movl   $0xf0102464,(%esp)
f010093a:	e8 e4 03 00 00       	call   f0100d23 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010093f:	c7 44 24 08 00 33 11 	movl   $0x113300,0x8(%esp)
f0100946:	00 
f0100947:	c7 44 24 04 00 33 11 	movl   $0xf0113300,0x4(%esp)
f010094e:	f0 
f010094f:	c7 04 24 88 24 10 f0 	movl   $0xf0102488,(%esp)
f0100956:	e8 c8 03 00 00       	call   f0100d23 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010095b:	c7 44 24 08 60 39 11 	movl   $0x113960,0x8(%esp)
f0100962:	00 
f0100963:	c7 44 24 04 60 39 11 	movl   $0xf0113960,0x4(%esp)
f010096a:	f0 
f010096b:	c7 04 24 ac 24 10 f0 	movl   $0xf01024ac,(%esp)
f0100972:	e8 ac 03 00 00       	call   f0100d23 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100977:	b8 5f 3d 11 f0       	mov    $0xf0113d5f,%eax
f010097c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100981:	89 c2                	mov    %eax,%edx
f0100983:	c1 fa 1f             	sar    $0x1f,%edx
f0100986:	c1 ea 16             	shr    $0x16,%edx
f0100989:	8d 04 02             	lea    (%edx,%eax,1),%eax
f010098c:	c1 f8 0a             	sar    $0xa,%eax
f010098f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100993:	c7 04 24 d0 24 10 f0 	movl   $0xf01024d0,(%esp)
f010099a:	e8 84 03 00 00       	call   f0100d23 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010099f:	b8 00 00 00 00       	mov    $0x0,%eax
f01009a4:	c9                   	leave  
f01009a5:	c3                   	ret    

f01009a6 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01009a6:	55                   	push   %ebp
f01009a7:	89 e5                	mov    %esp,%ebp
f01009a9:	57                   	push   %edi
f01009aa:	56                   	push   %esi
f01009ab:	53                   	push   %ebx
f01009ac:	83 ec 1c             	sub    $0x1c,%esp
f01009af:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01009b4:	be 04 26 10 f0       	mov    $0xf0102604,%esi
f01009b9:	bf 00 26 10 f0       	mov    $0xf0102600,%edi
f01009be:	8b 04 1e             	mov    (%esi,%ebx,1),%eax
f01009c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009c5:	8b 04 1f             	mov    (%edi,%ebx,1),%eax
f01009c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cc:	c7 04 24 41 23 10 f0 	movl   $0xf0102341,(%esp)
f01009d3:	e8 4b 03 00 00       	call   f0100d23 <cprintf>
f01009d8:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01009db:	83 fb 30             	cmp    $0x30,%ebx
f01009de:	75 de                	jne    f01009be <mon_help+0x18>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01009e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01009e5:	83 c4 1c             	add    $0x1c,%esp
f01009e8:	5b                   	pop    %ebx
f01009e9:	5e                   	pop    %esi
f01009ea:	5f                   	pop    %edi
f01009eb:	5d                   	pop    %ebp
f01009ec:	c3                   	ret    

f01009ed <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01009ed:	55                   	push   %ebp
f01009ee:	89 e5                	mov    %esp,%ebp
f01009f0:	57                   	push   %edi
f01009f1:	56                   	push   %esi
f01009f2:	53                   	push   %ebx
f01009f3:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009f6:	c7 04 24 fc 24 10 f0 	movl   $0xf01024fc,(%esp)
f01009fd:	e8 21 03 00 00       	call   f0100d23 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a02:	c7 04 24 20 25 10 f0 	movl   $0xf0102520,(%esp)
f0100a09:	e8 15 03 00 00       	call   f0100d23 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100a0e:	c7 04 24 4a 23 10 f0 	movl   $0xf010234a,(%esp)
f0100a15:	e8 46 0e 00 00       	call   f0101860 <readline>
f0100a1a:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100a1c:	85 c0                	test   %eax,%eax
f0100a1e:	74 ee                	je     f0100a0e <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a20:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f0100a27:	be 00 00 00 00       	mov    $0x0,%esi
f0100a2c:	eb 06                	jmp    f0100a34 <monitor+0x47>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a2e:	c6 03 00             	movb   $0x0,(%ebx)
f0100a31:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a34:	0f b6 03             	movzbl (%ebx),%eax
f0100a37:	84 c0                	test   %al,%al
f0100a39:	74 6a                	je     f0100aa5 <monitor+0xb8>
f0100a3b:	0f be c0             	movsbl %al,%eax
f0100a3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a42:	c7 04 24 4e 23 10 f0 	movl   $0xf010234e,(%esp)
f0100a49:	e8 40 10 00 00       	call   f0101a8e <strchr>
f0100a4e:	85 c0                	test   %eax,%eax
f0100a50:	75 dc                	jne    f0100a2e <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100a52:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a55:	74 4e                	je     f0100aa5 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a57:	83 fe 0f             	cmp    $0xf,%esi
f0100a5a:	75 16                	jne    f0100a72 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a5c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a63:	00 
f0100a64:	c7 04 24 53 23 10 f0 	movl   $0xf0102353,(%esp)
f0100a6b:	e8 b3 02 00 00       	call   f0100d23 <cprintf>
f0100a70:	eb 9c                	jmp    f0100a0e <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100a72:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a76:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a79:	0f b6 03             	movzbl (%ebx),%eax
f0100a7c:	84 c0                	test   %al,%al
f0100a7e:	75 0c                	jne    f0100a8c <monitor+0x9f>
f0100a80:	eb b2                	jmp    f0100a34 <monitor+0x47>
			buf++;
f0100a82:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a85:	0f b6 03             	movzbl (%ebx),%eax
f0100a88:	84 c0                	test   %al,%al
f0100a8a:	74 a8                	je     f0100a34 <monitor+0x47>
f0100a8c:	0f be c0             	movsbl %al,%eax
f0100a8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a93:	c7 04 24 4e 23 10 f0 	movl   $0xf010234e,(%esp)
f0100a9a:	e8 ef 0f 00 00       	call   f0101a8e <strchr>
f0100a9f:	85 c0                	test   %eax,%eax
f0100aa1:	74 df                	je     f0100a82 <monitor+0x95>
f0100aa3:	eb 8f                	jmp    f0100a34 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100aa5:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100aac:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100aad:	85 f6                	test   %esi,%esi
f0100aaf:	90                   	nop
f0100ab0:	0f 84 58 ff ff ff    	je     f0100a0e <monitor+0x21>
f0100ab6:	bb 00 26 10 f0       	mov    $0xf0102600,%ebx
f0100abb:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100ac0:	8b 03                	mov    (%ebx),%eax
f0100ac2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ac6:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ac9:	89 04 24             	mov    %eax,(%esp)
f0100acc:	e8 48 0f 00 00       	call   f0101a19 <strcmp>
f0100ad1:	85 c0                	test   %eax,%eax
f0100ad3:	75 23                	jne    f0100af8 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100ad5:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100ad8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100adb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100adf:	8d 45 a8             	lea    -0x58(%ebp),%eax
f0100ae2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ae6:	89 34 24             	mov    %esi,(%esp)
f0100ae9:	ff 97 08 26 10 f0    	call   *-0xfefd9f8(%edi)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100aef:	85 c0                	test   %eax,%eax
f0100af1:	78 28                	js     f0100b1b <monitor+0x12e>
f0100af3:	e9 16 ff ff ff       	jmp    f0100a0e <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100af8:	83 c7 01             	add    $0x1,%edi
f0100afb:	83 c3 0c             	add    $0xc,%ebx
f0100afe:	83 ff 04             	cmp    $0x4,%edi
f0100b01:	75 bd                	jne    f0100ac0 <monitor+0xd3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b03:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b0a:	c7 04 24 70 23 10 f0 	movl   $0xf0102370,(%esp)
f0100b11:	e8 0d 02 00 00       	call   f0100d23 <cprintf>
f0100b16:	e9 f3 fe ff ff       	jmp    f0100a0e <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100b1b:	83 c4 5c             	add    $0x5c,%esp
f0100b1e:	5b                   	pop    %ebx
f0100b1f:	5e                   	pop    %esi
f0100b20:	5f                   	pop    %edi
f0100b21:	5d                   	pop    %ebp
f0100b22:	c3                   	ret    

f0100b23 <mon_time>:
	return 0;
}

int
mon_time(int argc, char **argv, struct Trapframe *tf)
{
f0100b23:	55                   	push   %ebp
f0100b24:	89 e5                	mov    %esp,%ebp
f0100b26:	57                   	push   %edi
f0100b27:	56                   	push   %esi
f0100b28:	53                   	push   %ebx
f0100b29:	83 ec 2c             	sub    $0x2c,%esp
	uint32_t end_high = 0;
	int i;

	if (argc == 1) {
		cprintf("Please enter: time [command]\n");
		return 0;
f0100b2c:	bb 00 26 10 f0       	mov    $0xf0102600,%ebx
f0100b31:	be 00 00 00 00       	mov    $0x0,%esi
	uint32_t begin_high = 0;
	uint32_t end_low = 0;
	uint32_t end_high = 0;
	int i;

	if (argc == 1) {
f0100b36:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100b3a:	75 11                	jne    f0100b4d <mon_time+0x2a>
		cprintf("Please enter: time [command]\n");
f0100b3c:	c7 04 24 86 23 10 f0 	movl   $0xf0102386,(%esp)
f0100b43:	e8 db 01 00 00       	call   f0100d23 <cprintf>
		return 0;
f0100b48:	e9 96 00 00 00       	jmp    f0100be3 <mon_time+0xc0>
	}
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[1], commands[i].name) == 0)
f0100b4d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100b50:	83 c7 04             	add    $0x4,%edi
f0100b53:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100b56:	8b 03                	mov    (%ebx),%eax
f0100b58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b5c:	8b 07                	mov    (%edi),%eax
f0100b5e:	89 04 24             	mov    %eax,(%esp)
f0100b61:	e8 b3 0e 00 00       	call   f0101a19 <strcmp>
f0100b66:	85 c0                	test   %eax,%eax
f0100b68:	74 27                	je     f0100b91 <mon_time+0x6e>
			break;
		if (i == NCOMMANDS-1) {
f0100b6a:	83 fe 03             	cmp    $0x3,%esi
f0100b6d:	75 17                	jne    f0100b86 <mon_time+0x63>
			cprintf("Unknown command after time '%s'\n", argv[1]);
f0100b6f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b72:	8b 02                	mov    (%edx),%eax
f0100b74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b78:	c7 04 24 48 25 10 f0 	movl   $0xf0102548,(%esp)
f0100b7f:	e8 9f 01 00 00       	call   f0100d23 <cprintf>
			return 0;
f0100b84:	eb 5d                	jmp    f0100be3 <mon_time+0xc0>

	if (argc == 1) {
		cprintf("Please enter: time [command]\n");
		return 0;
	}
	for (i = 0; i < NCOMMANDS; i++) {
f0100b86:	83 c6 01             	add    $0x1,%esi
f0100b89:	83 c3 0c             	add    $0xc,%ebx
f0100b8c:	83 fe 04             	cmp    $0x4,%esi
f0100b8f:	75 c2                	jne    f0100b53 <mon_time+0x30>
		}
	}
	argc--;
	argv++;

	__asm __volatile("rdtsc" : "=a" (begin_low), "=d" (begin_high));
f0100b91:	0f 31                	rdtsc  
f0100b93:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b96:	89 c3                	mov    %eax,%ebx
	commands[i].func(argc, argv, tf);
f0100b98:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100b9b:	8b 55 10             	mov    0x10(%ebp),%edx
f0100b9e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100ba2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ba5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ba9:	8b 55 08             	mov    0x8(%ebp),%edx
f0100bac:	83 ea 01             	sub    $0x1,%edx
f0100baf:	89 14 24             	mov    %edx,(%esp)
f0100bb2:	ff 14 85 08 26 10 f0 	call   *-0xfefd9f8(,%eax,4)
	__asm __volatile("rdtsc" : "=a" (end_low), "=d" (end_high));
f0100bb9:	0f 31                	rdtsc  
	
	uint64_t begin_total = ((uint64_t)begin_high << 32) | begin_low; 
	uint64_t end_total = ((uint64_t)end_high << 32) | end_low; 
	cprintf("%s cycles: %llu\n", argv[0], end_total-begin_total);
f0100bbb:	89 c6                	mov    %eax,%esi
f0100bbd:	89 d7                	mov    %edx,%edi
f0100bbf:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100bc2:	29 de                	sub    %ebx,%esi
f0100bc4:	19 d7                	sbb    %edx,%edi
f0100bc6:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100bca:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100bce:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100bd1:	8b 02                	mov    (%edx),%eax
f0100bd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bd7:	c7 04 24 a4 23 10 f0 	movl   $0xf01023a4,(%esp)
f0100bde:	e8 40 01 00 00       	call   f0100d23 <cprintf>

	return 0;
}
f0100be3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be8:	83 c4 2c             	add    $0x2c,%esp
f0100beb:	5b                   	pop    %ebx
f0100bec:	5e                   	pop    %esi
f0100bed:	5f                   	pop    %edi
f0100bee:	5d                   	pop    %ebp
f0100bef:	c3                   	ret    

f0100bf0 <mon_backtrace>:
        start_overflow();
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100bf0:	55                   	push   %ebp
f0100bf1:	89 e5                	mov    %esp,%ebp
f0100bf3:	57                   	push   %edi
f0100bf4:	56                   	push   %esi
f0100bf5:	53                   	push   %ebx
f0100bf6:	83 ec 5c             	sub    $0x5c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100bf9:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t ebp = read_ebp();
	uint32_t eip = read_eip();
f0100bfb:	e8 90 fb ff ff       	call   f0100790 <read_eip>

	cprintf("Stack backtrace:\n");
f0100c00:	c7 04 24 b5 23 10 f0 	movl   $0xf01023b5,(%esp)
f0100c07:	e8 17 01 00 00       	call   f0100d23 <cprintf>
	while(ebp != 0x0) {
f0100c0c:	85 db                	test   %ebx,%ebx
f0100c0e:	0f 84 be 00 00 00    	je     f0100cd2 <mon_backtrace+0xe2>
		eip = *((uint32_t*)ebp + 1);
f0100c14:	8b 43 04             	mov    0x4(%ebx),%eax
f0100c17:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n", eip, ebp, *((uint32_t*)ebp+2), *((uint32_t*)ebp+3), *((uint32_t*)ebp+4), *((uint32_t*)ebp+5), *((uint32_t*)ebp+6) );
f0100c1a:	8b 43 18             	mov    0x18(%ebx),%eax
f0100c1d:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100c21:	8b 43 14             	mov    0x14(%ebx),%eax
f0100c24:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100c28:	8b 43 10             	mov    0x10(%ebx),%eax
f0100c2b:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100c2f:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100c32:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100c36:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c39:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c3d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c41:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c48:	c7 04 24 6c 25 10 f0 	movl   $0xf010256c,(%esp)
f0100c4f:	e8 cf 00 00 00       	call   f0100d23 <cprintf>
		
		// debug info, zhe ge hai yao suan fen, WTF
		struct Eipdebuginfo info;
		if (debuginfo_eip(eip, &info) == 0) {
f0100c54:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100c57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c5b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c5e:	89 04 24             	mov    %eax,(%esp)
f0100c61:	e8 28 02 00 00       	call   f0100e8e <debuginfo_eip>
f0100c66:	85 c0                	test   %eax,%eax
f0100c68:	75 5e                	jne    f0100cc8 <mon_backtrace+0xd8>
f0100c6a:	89 65 c0             	mov    %esp,-0x40(%ebp)
			char temp[info.eip_fn_namelen+1];
f0100c6d:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c70:	8d 46 1f             	lea    0x1f(%esi),%eax
f0100c73:	83 e0 f0             	and    $0xfffffff0,%eax
f0100c76:	29 c4                	sub    %eax,%esp
f0100c78:	8d 4c 24 2f          	lea    0x2f(%esp),%ecx
f0100c7c:	83 e1 f0             	and    $0xfffffff0,%ecx
			temp[info.eip_fn_namelen] = '\0';
f0100c7f:	c6 04 31 00          	movb   $0x0,(%ecx,%esi,1)
			int i = 0;
			for (i = 0; i < info.eip_fn_namelen; i++) {
f0100c83:	85 f6                	test   %esi,%esi
f0100c85:	7e 16                	jle    f0100c9d <mon_backtrace+0xad>
				temp[i] = info.eip_fn_name[i];
f0100c87:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100c8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8f:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
f0100c93:	88 14 01             	mov    %dl,(%ecx,%eax,1)
		struct Eipdebuginfo info;
		if (debuginfo_eip(eip, &info) == 0) {
			char temp[info.eip_fn_namelen+1];
			temp[info.eip_fn_namelen] = '\0';
			int i = 0;
			for (i = 0; i < info.eip_fn_namelen; i++) {
f0100c96:	83 c0 01             	add    $0x1,%eax
f0100c99:	39 f0                	cmp    %esi,%eax
f0100c9b:	75 f2                	jne    f0100c8f <mon_backtrace+0x9f>
				temp[i] = info.eip_fn_name[i];
			}
			cprintf("         %s:%d: %s+%x\n", info.eip_file, info.eip_line, temp, eip-info.eip_fn_addr);
f0100c9d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ca0:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100ca3:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100ca7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cae:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cb2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100cb5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cb9:	c7 04 24 c7 23 10 f0 	movl   $0xf01023c7,(%esp)
f0100cc0:	e8 5e 00 00 00       	call   f0100d23 <cprintf>
f0100cc5:	8b 65 c0             	mov    -0x40(%ebp),%esp
		}
		// debug info end

		ebp = *((uint32_t*)ebp);
f0100cc8:	8b 1b                	mov    (%ebx),%ebx
	// Your code here.
	uint32_t ebp = read_ebp();
	uint32_t eip = read_eip();

	cprintf("Stack backtrace:\n");
	while(ebp != 0x0) {
f0100cca:	85 db                	test   %ebx,%ebx
f0100ccc:	0f 85 42 ff ff ff    	jne    f0100c14 <mon_backtrace+0x24>

		ebp = *((uint32_t*)ebp);
	}
	
	
    overflow_me();
f0100cd2:	e8 fd fb ff ff       	call   f01008d4 <overflow_me>
    cprintf("Backtrace success\n");
f0100cd7:	c7 04 24 de 23 10 f0 	movl   $0xf01023de,(%esp)
f0100cde:	e8 40 00 00 00       	call   f0100d23 <cprintf>
	return 0;
}
f0100ce3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ceb:	5b                   	pop    %ebx
f0100cec:	5e                   	pop    %esi
f0100ced:	5f                   	pop    %edi
f0100cee:	5d                   	pop    %ebp
f0100cef:	c3                   	ret    

f0100cf0 <vcprintf>:
    (*cnt)++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f0100cf0:	55                   	push   %ebp
f0100cf1:	89 e5                	mov    %esp,%ebp
f0100cf3:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100cf6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100cfd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d00:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d04:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d07:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d0b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100d0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d12:	c7 04 24 3d 0d 10 f0 	movl   $0xf0100d3d,(%esp)
f0100d19:	e8 c1 05 00 00       	call   f01012df <vprintfmt>
	return cnt;
}
f0100d1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d21:	c9                   	leave  
f0100d22:	c3                   	ret    

f0100d23 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100d23:	55                   	push   %ebp
f0100d24:	89 e5                	mov    %esp,%ebp
f0100d26:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100d29:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100d2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d30:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d33:	89 04 24             	mov    %eax,(%esp)
f0100d36:	e8 b5 ff ff ff       	call   f0100cf0 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100d3b:	c9                   	leave  
f0100d3c:	c3                   	ret    

f0100d3d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100d3d:	55                   	push   %ebp
f0100d3e:	89 e5                	mov    %esp,%ebp
f0100d40:	53                   	push   %ebx
f0100d41:	83 ec 14             	sub    $0x14,%esp
f0100d44:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0100d47:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d4a:	89 04 24             	mov    %eax,(%esp)
f0100d4d:	e8 38 f8 ff ff       	call   f010058a <cputchar>
    (*cnt)++;
f0100d52:	83 03 01             	addl   $0x1,(%ebx)
}
f0100d55:	83 c4 14             	add    $0x14,%esp
f0100d58:	5b                   	pop    %ebx
f0100d59:	5d                   	pop    %ebp
f0100d5a:	c3                   	ret    
f0100d5b:	00 00                	add    %al,(%eax)
f0100d5d:	00 00                	add    %al,(%eax)
	...

f0100d60 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100d60:	55                   	push   %ebp
f0100d61:	89 e5                	mov    %esp,%ebp
f0100d63:	57                   	push   %edi
f0100d64:	56                   	push   %esi
f0100d65:	53                   	push   %ebx
f0100d66:	83 ec 14             	sub    $0x14,%esp
f0100d69:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100d6c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100d6f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100d72:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100d75:	8b 1a                	mov    (%edx),%ebx
f0100d77:	8b 01                	mov    (%ecx),%eax
f0100d79:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0100d7c:	39 c3                	cmp    %eax,%ebx
f0100d7e:	0f 8f 9c 00 00 00    	jg     f0100e20 <stab_binsearch+0xc0>
f0100d84:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f0100d8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d8e:	01 d8                	add    %ebx,%eax
f0100d90:	89 c7                	mov    %eax,%edi
f0100d92:	c1 ef 1f             	shr    $0x1f,%edi
f0100d95:	01 c7                	add    %eax,%edi
f0100d97:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d99:	39 df                	cmp    %ebx,%edi
f0100d9b:	7c 33                	jl     f0100dd0 <stab_binsearch+0x70>
f0100d9d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100da0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100da3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100da8:	39 f0                	cmp    %esi,%eax
f0100daa:	0f 84 bc 00 00 00    	je     f0100e6c <stab_binsearch+0x10c>
f0100db0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f0100db4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f0100db8:	89 f8                	mov    %edi,%eax
			m--;
f0100dba:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100dbd:	39 d8                	cmp    %ebx,%eax
f0100dbf:	7c 0f                	jl     f0100dd0 <stab_binsearch+0x70>
f0100dc1:	0f b6 0a             	movzbl (%edx),%ecx
f0100dc4:	83 ea 0c             	sub    $0xc,%edx
f0100dc7:	39 f1                	cmp    %esi,%ecx
f0100dc9:	75 ef                	jne    f0100dba <stab_binsearch+0x5a>
f0100dcb:	e9 9e 00 00 00       	jmp    f0100e6e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100dd0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100dd3:	eb 3c                	jmp    f0100e11 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100dd5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100dd8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100dda:	8d 5f 01             	lea    0x1(%edi),%ebx
f0100ddd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100de4:	eb 2b                	jmp    f0100e11 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f0100de6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100de9:	76 14                	jbe    f0100dff <stab_binsearch+0x9f>
			*region_right = m - 1;
f0100deb:	83 e8 01             	sub    $0x1,%eax
f0100dee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100df1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100df4:	89 02                	mov    %eax,(%edx)
f0100df6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100dfd:	eb 12                	jmp    f0100e11 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100dff:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100e02:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100e04:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100e08:	89 c3                	mov    %eax,%ebx
f0100e0a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100e11:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100e14:	0f 8d 71 ff ff ff    	jge    f0100d8b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100e1a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e1e:	75 0f                	jne    f0100e2f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100e20:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100e23:	8b 03                	mov    (%ebx),%eax
f0100e25:	83 e8 01             	sub    $0x1,%eax
f0100e28:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e2b:	89 02                	mov    %eax,(%edx)
f0100e2d:	eb 57                	jmp    f0100e86 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e2f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e32:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100e34:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100e37:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e39:	39 c1                	cmp    %eax,%ecx
f0100e3b:	7d 28                	jge    f0100e65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100e3d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e40:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100e43:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100e48:	39 f2                	cmp    %esi,%edx
f0100e4a:	74 19                	je     f0100e65 <stab_binsearch+0x105>
f0100e4c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100e50:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100e54:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e57:	39 c1                	cmp    %eax,%ecx
f0100e59:	7d 0a                	jge    f0100e65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100e5b:	0f b6 1a             	movzbl (%edx),%ebx
f0100e5e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e61:	39 f3                	cmp    %esi,%ebx
f0100e63:	75 ef                	jne    f0100e54 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100e65:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100e68:	89 02                	mov    %eax,(%edx)
f0100e6a:	eb 1a                	jmp    f0100e86 <stab_binsearch+0x126>
	}
}
f0100e6c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100e6e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e71:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100e74:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100e78:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100e7b:	0f 82 54 ff ff ff    	jb     f0100dd5 <stab_binsearch+0x75>
f0100e81:	e9 60 ff ff ff       	jmp    f0100de6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100e86:	83 c4 14             	add    $0x14,%esp
f0100e89:	5b                   	pop    %ebx
f0100e8a:	5e                   	pop    %esi
f0100e8b:	5f                   	pop    %edi
f0100e8c:	5d                   	pop    %ebp
f0100e8d:	c3                   	ret    

f0100e8e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100e8e:	55                   	push   %ebp
f0100e8f:	89 e5                	mov    %esp,%ebp
f0100e91:	83 ec 48             	sub    $0x48,%esp
f0100e94:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100e97:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100e9a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100e9d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ea0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ea3:	c7 03 30 26 10 f0    	movl   $0xf0102630,(%ebx)
	info->eip_line = 0;
f0100ea9:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100eb0:	c7 43 08 30 26 10 f0 	movl   $0xf0102630,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100eb7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ebe:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ec1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ec8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ece:	76 12                	jbe    f0100ee2 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ed0:	b8 9c 86 10 f0       	mov    $0xf010869c,%eax
f0100ed5:	3d 9d 6a 10 f0       	cmp    $0xf0106a9d,%eax
f0100eda:	0f 86 aa 01 00 00    	jbe    f010108a <debuginfo_eip+0x1fc>
f0100ee0:	eb 1c                	jmp    f0100efe <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ee2:	c7 44 24 08 3a 26 10 	movl   $0xf010263a,0x8(%esp)
f0100ee9:	f0 
f0100eea:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ef1:	00 
f0100ef2:	c7 04 24 47 26 10 f0 	movl   $0xf0102647,(%esp)
f0100ef9:	e8 87 f1 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100efe:	80 3d 9b 86 10 f0 00 	cmpb   $0x0,0xf010869b
f0100f05:	0f 85 7f 01 00 00    	jne    f010108a <debuginfo_eip+0x1fc>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100f0b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100f12:	b8 9c 6a 10 f0       	mov    $0xf0106a9c,%eax
f0100f17:	2d e4 28 10 f0       	sub    $0xf01028e4,%eax
f0100f1c:	c1 f8 02             	sar    $0x2,%eax
f0100f1f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100f25:	83 e8 01             	sub    $0x1,%eax
f0100f28:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100f2b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100f2e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100f31:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f35:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100f3c:	b8 e4 28 10 f0       	mov    $0xf01028e4,%eax
f0100f41:	e8 1a fe ff ff       	call   f0100d60 <stab_binsearch>
	if (lfile == 0)
f0100f46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f49:	85 c0                	test   %eax,%eax
f0100f4b:	0f 84 39 01 00 00    	je     f010108a <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100f51:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100f54:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f57:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100f5a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100f5d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f60:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f64:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100f6b:	b8 e4 28 10 f0       	mov    $0xf01028e4,%eax
f0100f70:	e8 eb fd ff ff       	call   f0100d60 <stab_binsearch>

	if (lfun <= rfun) {
f0100f75:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f78:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100f7b:	7f 3c                	jg     f0100fb9 <debuginfo_eip+0x12b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100f7d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f80:	8b 80 e4 28 10 f0    	mov    -0xfefd71c(%eax),%eax
f0100f86:	ba 9c 86 10 f0       	mov    $0xf010869c,%edx
f0100f8b:	81 ea 9d 6a 10 f0    	sub    $0xf0106a9d,%edx
f0100f91:	39 d0                	cmp    %edx,%eax
f0100f93:	73 08                	jae    f0100f9d <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100f95:	05 9d 6a 10 f0       	add    $0xf0106a9d,%eax
f0100f9a:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100f9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fa0:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100fa3:	8b 92 ec 28 10 f0    	mov    -0xfefd714(%edx),%edx
f0100fa9:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100fac:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100fae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100fb1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100fb4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100fb7:	eb 0f                	jmp    f0100fc8 <debuginfo_eip+0x13a>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100fb9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100fbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fbf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100fc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fc5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100fc8:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100fcf:	00 
f0100fd0:	8b 43 08             	mov    0x8(%ebx),%eax
f0100fd3:	89 04 24             	mov    %eax,(%esp)
f0100fd6:	e8 e0 0a 00 00       	call   f0101abb <strfind>
f0100fdb:	2b 43 08             	sub    0x8(%ebx),%eax
f0100fde:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100fe1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100fe4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100fe7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100feb:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100ff2:	b8 e4 28 10 f0       	mov    $0xf01028e4,%eax
f0100ff7:	e8 64 fd ff ff       	call   f0100d60 <stab_binsearch>
	if (lline > rline)
f0100ffc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fff:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0101002:	7e 18                	jle    f010101c <debuginfo_eip+0x18e>
		info->eip_line = -1;
f0101004:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f010100b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010100e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101011:	6b d0 0c             	imul   $0xc,%eax,%edx
f0101014:	81 c2 ec 28 10 f0    	add    $0xf01028ec,%edx
f010101a:	eb 15                	jmp    f0101031 <debuginfo_eip+0x1a3>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline)
		info->eip_line = -1;
	else
		info->eip_line = stabs[lline].n_desc;
f010101c:	6b c0 0c             	imul   $0xc,%eax,%eax
f010101f:	0f b7 80 ea 28 10 f0 	movzwl -0xfefd716(%eax),%eax
f0101026:	89 43 04             	mov    %eax,0x4(%ebx)
f0101029:	eb e0                	jmp    f010100b <debuginfo_eip+0x17d>
f010102b:	83 e8 01             	sub    $0x1,%eax
f010102e:	83 ea 0c             	sub    $0xc,%edx
f0101031:	89 c6                	mov    %eax,%esi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101033:	39 f8                	cmp    %edi,%eax
f0101035:	7c 22                	jl     f0101059 <debuginfo_eip+0x1cb>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101037:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010103b:	80 f9 84             	cmp    $0x84,%cl
f010103e:	74 64                	je     f01010a4 <debuginfo_eip+0x216>
f0101040:	80 f9 64             	cmp    $0x64,%cl
f0101043:	75 e6                	jne    f010102b <debuginfo_eip+0x19d>
f0101045:	83 3a 00             	cmpl   $0x0,(%edx)
f0101048:	74 e1                	je     f010102b <debuginfo_eip+0x19d>
f010104a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101050:	eb 52                	jmp    f01010a4 <debuginfo_eip+0x216>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101052:	05 9d 6a 10 f0       	add    $0xf0106a9d,%eax
f0101057:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101059:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010105c:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f010105f:	7d 31                	jge    f0101092 <debuginfo_eip+0x204>
		for (lline = lfun + 1;
f0101061:	83 c0 01             	add    $0x1,%eax
f0101064:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101067:	ba e4 28 10 f0       	mov    $0xf01028e4,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010106c:	eb 08                	jmp    f0101076 <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010106e:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0101072:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101076:	8b 45 d4             	mov    -0x2c(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101079:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f010107c:	7d 14                	jge    f0101092 <debuginfo_eip+0x204>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010107e:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101081:	80 7c 10 04 a0       	cmpb   $0xa0,0x4(%eax,%edx,1)
f0101086:	74 e6                	je     f010106e <debuginfo_eip+0x1e0>
f0101088:	eb 08                	jmp    f0101092 <debuginfo_eip+0x204>
f010108a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010108f:	90                   	nop
f0101090:	eb 05                	jmp    f0101097 <debuginfo_eip+0x209>
f0101092:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0101097:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010109a:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010109d:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01010a0:	89 ec                	mov    %ebp,%esp
f01010a2:	5d                   	pop    %ebp
f01010a3:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01010a4:	6b c6 0c             	imul   $0xc,%esi,%eax
f01010a7:	8b 80 e4 28 10 f0    	mov    -0xfefd71c(%eax),%eax
f01010ad:	ba 9c 86 10 f0       	mov    $0xf010869c,%edx
f01010b2:	81 ea 9d 6a 10 f0    	sub    $0xf0106a9d,%edx
f01010b8:	39 d0                	cmp    %edx,%eax
f01010ba:	72 96                	jb     f0101052 <debuginfo_eip+0x1c4>
f01010bc:	eb 9b                	jmp    f0101059 <debuginfo_eip+0x1cb>
	...

f01010c0 <printnum>:
static int padding_max_width = 0;
static int one_number_flag = 0; // 0 init, 1 one, 2 more than one
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01010c0:	55                   	push   %ebp
f01010c1:	89 e5                	mov    %esp,%ebp
f01010c3:	57                   	push   %edi
f01010c4:	56                   	push   %esi
f01010c5:	53                   	push   %ebx
f01010c6:	83 ec 4c             	sub    $0x4c,%esp
f01010c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010cc:	89 d7                	mov    %edx,%edi
f01010ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01010d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010d4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010d7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010da:	8b 45 10             	mov    0x10(%ebp),%eax
f01010dd:	8b 75 18             	mov    0x18(%ebp),%esi
	// you can add helper function if needed.
	// // your code here:
	// if (padc == '+')
	// 	putch(padc, putdat);

	if (padc == '-' && width > padding_max_width)
f01010e0:	83 fe 2d             	cmp    $0x2d,%esi
f01010e3:	75 11                	jne    f01010f6 <printnum+0x36>
f01010e5:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01010e8:	39 0d 48 35 11 f0    	cmp    %ecx,0xf0113548
f01010ee:	7d 06                	jge    f01010f6 <printnum+0x36>
		padding_max_width = width;
f01010f0:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548

	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01010f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01010f9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010fe:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0101101:	72 07                	jb     f010110a <printnum+0x4a>
f0101103:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101106:	39 d0                	cmp    %edx,%eax
f0101108:	77 7a                	ja     f0101184 <printnum+0xc4>
		if (padc == '-' && one_number_flag == 0)
f010110a:	83 fe 2d             	cmp    $0x2d,%esi
f010110d:	75 13                	jne    f0101122 <printnum+0x62>
f010110f:	83 3d 4c 35 11 f0 00 	cmpl   $0x0,0xf011354c
f0101116:	75 0a                	jne    f0101122 <printnum+0x62>
			one_number_flag = 2;
f0101118:	c7 05 4c 35 11 f0 02 	movl   $0x2,0xf011354c
f010111f:	00 00 00 
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101122:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101126:	8b 55 14             	mov    0x14(%ebp),%edx
f0101129:	83 ea 01             	sub    $0x1,%edx
f010112c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101130:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101134:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101138:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f010113c:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010113f:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101142:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101145:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101149:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101150:	00 
f0101151:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101154:	89 04 24             	mov    %eax,(%esp)
f0101157:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010115a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010115e:	e8 ed 0b 00 00       	call   f0101d50 <__udivdi3>
f0101163:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101166:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101169:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010116d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101171:	89 04 24             	mov    %eax,(%esp)
f0101174:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101178:	89 fa                	mov    %edi,%edx
f010117a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010117d:	e8 3e ff ff ff       	call   f01010c0 <printnum>
f0101182:	eb 4b                	jmp    f01011cf <printnum+0x10f>
	} else {
		if (padc == '-' && one_number_flag == 0)
f0101184:	83 fe 2d             	cmp    $0x2d,%esi
f0101187:	75 32                	jne    f01011bb <printnum+0xfb>
f0101189:	83 3d 4c 35 11 f0 00 	cmpl   $0x0,0xf011354c
f0101190:	75 30                	jne    f01011c2 <printnum+0x102>
			one_number_flag = 1;
f0101192:	c7 05 4c 35 11 f0 01 	movl   $0x1,0xf011354c
f0101199:	00 00 00 
f010119c:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010119f:	eb 24                	jmp    f01011c5 <printnum+0x105>
		// print any needed pad characters before first digit
		while (--width > 0) {
			if (padc != '-')
f01011a1:	83 fe 2d             	cmp    $0x2d,%esi
f01011a4:	74 0c                	je     f01011b2 <printnum+0xf2>
				putch(padc, putdat);
f01011a6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011aa:	89 34 24             	mov    %esi,(%esp)
f01011ad:	ff 55 e4             	call   *-0x1c(%ebp)
f01011b0:	eb 13                	jmp    f01011c5 <printnum+0x105>
			else
				padding_space++;
f01011b2:	83 05 50 35 11 f0 01 	addl   $0x1,0xf0113550
f01011b9:	eb 0a                	jmp    f01011c5 <printnum+0x105>
f01011bb:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01011be:	66 90                	xchg   %ax,%ax
f01011c0:	eb 03                	jmp    f01011c5 <printnum+0x105>
f01011c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		if (padc == '-' && one_number_flag == 0)
			one_number_flag = 1;
		// print any needed pad characters before first digit
		while (--width > 0) {
f01011c5:	83 eb 01             	sub    $0x1,%ebx
f01011c8:	85 db                	test   %ebx,%ebx
f01011ca:	7f d5                	jg     f01011a1 <printnum+0xe1>
f01011cc:	89 5d 14             	mov    %ebx,0x14(%ebp)
				padding_space++;
		}
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01011cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d3:	8b 04 24             	mov    (%esp),%eax
f01011d6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01011da:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011dd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011e0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01011e3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01011e7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01011ee:	00 
f01011ef:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01011f2:	89 0c 24             	mov    %ecx,(%esp)
f01011f5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01011f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011fc:	e8 7f 0c 00 00       	call   f0101e80 <__umoddi3>
f0101201:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101204:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101208:	0f be 80 55 26 10 f0 	movsbl -0xfefd9ab(%eax),%eax
f010120f:	89 04 24             	mov    %eax,(%esp)
f0101212:	ff 55 e4             	call   *-0x1c(%ebp)
	if ((width == padding_max_width || one_number_flag == 1) && padc == '-') {
f0101215:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101218:	3b 0d 48 35 11 f0    	cmp    0xf0113548,%ecx
f010121e:	74 09                	je     f0101229 <printnum+0x169>
f0101220:	83 3d 4c 35 11 f0 01 	cmpl   $0x1,0xf011354c
f0101227:	75 57                	jne    f0101280 <printnum+0x1c0>
f0101229:	83 fe 2d             	cmp    $0x2d,%esi
f010122c:	75 52                	jne    f0101280 <printnum+0x1c0>
		while(padding_space-- > 0)
f010122e:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0101233:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101236:	89 15 50 35 11 f0    	mov    %edx,0xf0113550
f010123c:	85 c0                	test   %eax,%eax
f010123e:	7e 22                	jle    f0101262 <printnum+0x1a2>
f0101240:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			putch(' ', putdat);
f0101243:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101247:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010124e:	ff d3                	call   *%ebx
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
	if ((width == padding_max_width || one_number_flag == 1) && padc == '-') {
		while(padding_space-- > 0)
f0101250:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0101255:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101258:	89 15 50 35 11 f0    	mov    %edx,0xf0113550
f010125e:	85 c0                	test   %eax,%eax
f0101260:	7f e1                	jg     f0101243 <printnum+0x183>
			putch(' ', putdat);
		padding_space = 0;
f0101262:	c7 05 50 35 11 f0 00 	movl   $0x0,0xf0113550
f0101269:	00 00 00 
		padding_max_width = 0;
f010126c:	c7 05 48 35 11 f0 00 	movl   $0x0,0xf0113548
f0101273:	00 00 00 
		one_number_flag = 0;
f0101276:	c7 05 4c 35 11 f0 00 	movl   $0x0,0xf011354c
f010127d:	00 00 00 
	}
}
f0101280:	83 c4 4c             	add    $0x4c,%esp
f0101283:	5b                   	pop    %ebx
f0101284:	5e                   	pop    %esi
f0101285:	5f                   	pop    %edi
f0101286:	5d                   	pop    %ebp
f0101287:	c3                   	ret    

f0101288 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101288:	55                   	push   %ebp
f0101289:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010128b:	83 fa 01             	cmp    $0x1,%edx
f010128e:	7e 0e                	jle    f010129e <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101290:	8b 10                	mov    (%eax),%edx
f0101292:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101295:	89 08                	mov    %ecx,(%eax)
f0101297:	8b 02                	mov    (%edx),%eax
f0101299:	8b 52 04             	mov    0x4(%edx),%edx
f010129c:	eb 22                	jmp    f01012c0 <getuint+0x38>
	else if (lflag)
f010129e:	85 d2                	test   %edx,%edx
f01012a0:	74 10                	je     f01012b2 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01012a2:	8b 10                	mov    (%eax),%edx
f01012a4:	8d 4a 04             	lea    0x4(%edx),%ecx
f01012a7:	89 08                	mov    %ecx,(%eax)
f01012a9:	8b 02                	mov    (%edx),%eax
f01012ab:	ba 00 00 00 00       	mov    $0x0,%edx
f01012b0:	eb 0e                	jmp    f01012c0 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01012b2:	8b 10                	mov    (%eax),%edx
f01012b4:	8d 4a 04             	lea    0x4(%edx),%ecx
f01012b7:	89 08                	mov    %ecx,(%eax)
f01012b9:	8b 02                	mov    (%edx),%eax
f01012bb:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01012c0:	5d                   	pop    %ebp
f01012c1:	c3                   	ret    

f01012c2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01012c2:	55                   	push   %ebp
f01012c3:	89 e5                	mov    %esp,%ebp
f01012c5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01012c8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01012cc:	8b 10                	mov    (%eax),%edx
f01012ce:	3b 50 04             	cmp    0x4(%eax),%edx
f01012d1:	73 0a                	jae    f01012dd <sprintputch+0x1b>
		*b->buf++ = ch;
f01012d3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012d6:	88 0a                	mov    %cl,(%edx)
f01012d8:	83 c2 01             	add    $0x1,%edx
f01012db:	89 10                	mov    %edx,(%eax)
}
f01012dd:	5d                   	pop    %ebp
f01012de:	c3                   	ret    

f01012df <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01012df:	55                   	push   %ebp
f01012e0:	89 e5                	mov    %esp,%ebp
f01012e2:	57                   	push   %edi
f01012e3:	56                   	push   %esi
f01012e4:	53                   	push   %ebx
f01012e5:	83 ec 5c             	sub    $0x5c,%esp
f01012e8:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01012eb:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01012ee:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f01012f5:	eb 12                	jmp    f0101309 <vprintfmt+0x2a>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01012f7:	85 c0                	test   %eax,%eax
f01012f9:	0f 84 af 04 00 00    	je     f01017ae <vprintfmt+0x4cf>
				return;
			putch(ch, putdat);
f01012ff:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101303:	89 04 24             	mov    %eax,(%esp)
f0101306:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101309:	0f b6 03             	movzbl (%ebx),%eax
f010130c:	83 c3 01             	add    $0x1,%ebx
f010130f:	83 f8 25             	cmp    $0x25,%eax
f0101312:	75 e3                	jne    f01012f7 <vprintfmt+0x18>
f0101314:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0101318:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010131f:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0101324:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f010132b:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0101332:	eb 06                	jmp    f010133a <vprintfmt+0x5b>
f0101334:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0101338:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010133a:	0f b6 0b             	movzbl (%ebx),%ecx
f010133d:	0f b6 d1             	movzbl %cl,%edx
f0101340:	8d 43 01             	lea    0x1(%ebx),%eax
f0101343:	83 e9 23             	sub    $0x23,%ecx
f0101346:	80 f9 55             	cmp    $0x55,%cl
f0101349:	0f 87 41 04 00 00    	ja     f0101790 <vprintfmt+0x4b1>
f010134f:	0f b6 c9             	movzbl %cl,%ecx
f0101352:	ff 24 8d 60 27 10 f0 	jmp    *-0xfefd8a0(,%ecx,4)
f0101359:	c6 45 e0 2b          	movb   $0x2b,-0x20(%ebp)
f010135d:	eb d9                	jmp    f0101338 <vprintfmt+0x59>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010135f:	8d 72 d0             	lea    -0x30(%edx),%esi
				ch = *fmt;
f0101362:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0101365:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101368:	83 f9 09             	cmp    $0x9,%ecx
f010136b:	76 08                	jbe    f0101375 <vprintfmt+0x96>
f010136d:	eb 40                	jmp    f01013af <vprintfmt+0xd0>
f010136f:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
			goto reswitch;
f0101373:	eb c3                	jmp    f0101338 <vprintfmt+0x59>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101375:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0101378:	8d 0c b6             	lea    (%esi,%esi,4),%ecx
f010137b:	8d 74 4a d0          	lea    -0x30(%edx,%ecx,2),%esi
				ch = *fmt;
f010137f:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0101382:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101385:	83 f9 09             	cmp    $0x9,%ecx
f0101388:	76 eb                	jbe    f0101375 <vprintfmt+0x96>
f010138a:	eb 23                	jmp    f01013af <vprintfmt+0xd0>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010138c:	8b 55 14             	mov    0x14(%ebp),%edx
f010138f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101392:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101395:	8b 32                	mov    (%edx),%esi
			goto process_precision;
f0101397:	eb 16                	jmp    f01013af <vprintfmt+0xd0>

		case '.':
			if (width < 0)
f0101399:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010139c:	c1 fa 1f             	sar    $0x1f,%edx
f010139f:	f7 d2                	not    %edx
f01013a1:	21 55 dc             	and    %edx,-0x24(%ebp)
f01013a4:	eb 92                	jmp    f0101338 <vprintfmt+0x59>
f01013a6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f01013ad:	eb 89                	jmp    f0101338 <vprintfmt+0x59>

		process_precision:
			if (width < 0)
f01013af:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01013b3:	79 83                	jns    f0101338 <vprintfmt+0x59>
f01013b5:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01013b8:	8b 75 c8             	mov    -0x38(%ebp),%esi
f01013bb:	e9 78 ff ff ff       	jmp    f0101338 <vprintfmt+0x59>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01013c0:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
			goto reswitch;
f01013c4:	e9 6f ff ff ff       	jmp    f0101338 <vprintfmt+0x59>
f01013c9:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01013cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01013cf:	8d 50 04             	lea    0x4(%eax),%edx
f01013d2:	89 55 14             	mov    %edx,0x14(%ebp)
f01013d5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013d9:	8b 00                	mov    (%eax),%eax
f01013db:	89 04 24             	mov    %eax,(%esp)
f01013de:	ff 55 08             	call   *0x8(%ebp)
f01013e1:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f01013e4:	e9 20 ff ff ff       	jmp    f0101309 <vprintfmt+0x2a>
f01013e9:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f01013ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ef:	8d 50 04             	lea    0x4(%eax),%edx
f01013f2:	89 55 14             	mov    %edx,0x14(%ebp)
f01013f5:	8b 00                	mov    (%eax),%eax
f01013f7:	89 c2                	mov    %eax,%edx
f01013f9:	c1 fa 1f             	sar    $0x1f,%edx
f01013fc:	31 d0                	xor    %edx,%eax
f01013fe:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101400:	83 f8 06             	cmp    $0x6,%eax
f0101403:	7f 0b                	jg     f0101410 <vprintfmt+0x131>
f0101405:	8b 14 85 b8 28 10 f0 	mov    -0xfefd748(,%eax,4),%edx
f010140c:	85 d2                	test   %edx,%edx
f010140e:	75 23                	jne    f0101433 <vprintfmt+0x154>
				printfmt(putch, putdat, "error %d", err);
f0101410:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101414:	c7 44 24 08 66 26 10 	movl   $0xf0102666,0x8(%esp)
f010141b:	f0 
f010141c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101420:	8b 45 08             	mov    0x8(%ebp),%eax
f0101423:	89 04 24             	mov    %eax,(%esp)
f0101426:	e8 0b 04 00 00       	call   f0101836 <printfmt>
f010142b:	8b 5d cc             	mov    -0x34(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010142e:	e9 d6 fe ff ff       	jmp    f0101309 <vprintfmt+0x2a>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0101433:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101437:	c7 44 24 08 6f 26 10 	movl   $0xf010266f,0x8(%esp)
f010143e:	f0 
f010143f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101443:	8b 55 08             	mov    0x8(%ebp),%edx
f0101446:	89 14 24             	mov    %edx,(%esp)
f0101449:	e8 e8 03 00 00       	call   f0101836 <printfmt>
f010144e:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101451:	e9 b3 fe ff ff       	jmp    f0101309 <vprintfmt+0x2a>
f0101456:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101459:	89 c3                	mov    %eax,%ebx
f010145b:	89 f1                	mov    %esi,%ecx
f010145d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101460:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101463:	8b 45 14             	mov    0x14(%ebp),%eax
f0101466:	8d 50 04             	lea    0x4(%eax),%edx
f0101469:	89 55 14             	mov    %edx,0x14(%ebp)
f010146c:	8b 00                	mov    (%eax),%eax
f010146e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101471:	85 c0                	test   %eax,%eax
f0101473:	75 07                	jne    f010147c <vprintfmt+0x19d>
f0101475:	c7 45 d0 72 26 10 f0 	movl   $0xf0102672,-0x30(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f010147c:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f0101480:	7e 06                	jle    f0101488 <vprintfmt+0x1a9>
f0101482:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0101486:	75 13                	jne    f010149b <vprintfmt+0x1bc>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101488:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010148b:	0f be 02             	movsbl (%edx),%eax
f010148e:	85 c0                	test   %eax,%eax
f0101490:	0f 85 a2 00 00 00    	jne    f0101538 <vprintfmt+0x259>
f0101496:	e9 8f 00 00 00       	jmp    f010152a <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010149b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010149f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01014a2:	89 0c 24             	mov    %ecx,(%esp)
f01014a5:	e8 b1 04 00 00       	call   f010195b <strnlen>
f01014aa:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01014ad:	29 c2                	sub    %eax,%edx
f01014af:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01014b2:	85 d2                	test   %edx,%edx
f01014b4:	7e d2                	jle    f0101488 <vprintfmt+0x1a9>
					putch(padc, putdat);
f01014b6:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f01014ba:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01014bd:	89 5d c0             	mov    %ebx,-0x40(%ebp)
f01014c0:	89 d3                	mov    %edx,%ebx
f01014c2:	89 ce                	mov    %ecx,%esi
f01014c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014c8:	89 34 24             	mov    %esi,(%esp)
f01014cb:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01014ce:	83 eb 01             	sub    $0x1,%ebx
f01014d1:	85 db                	test   %ebx,%ebx
f01014d3:	7f ef                	jg     f01014c4 <vprintfmt+0x1e5>
f01014d5:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01014d8:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f01014db:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01014e2:	eb a4                	jmp    f0101488 <vprintfmt+0x1a9>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01014e4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014e8:	74 1b                	je     f0101505 <vprintfmt+0x226>
f01014ea:	8d 50 e0             	lea    -0x20(%eax),%edx
f01014ed:	83 fa 5e             	cmp    $0x5e,%edx
f01014f0:	76 13                	jbe    f0101505 <vprintfmt+0x226>
					putch('?', putdat);
f01014f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01014f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014f9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101500:	ff 55 08             	call   *0x8(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101503:	eb 0d                	jmp    f0101512 <vprintfmt+0x233>
					putch('?', putdat);
				else
					putch(ch, putdat);
f0101505:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101508:	89 54 24 04          	mov    %edx,0x4(%esp)
f010150c:	89 04 24             	mov    %eax,(%esp)
f010150f:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101512:	83 ef 01             	sub    $0x1,%edi
f0101515:	0f be 03             	movsbl (%ebx),%eax
f0101518:	85 c0                	test   %eax,%eax
f010151a:	74 05                	je     f0101521 <vprintfmt+0x242>
f010151c:	83 c3 01             	add    $0x1,%ebx
f010151f:	eb 28                	jmp    f0101549 <vprintfmt+0x26a>
f0101521:	89 7d dc             	mov    %edi,-0x24(%ebp)
f0101524:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101527:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010152a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010152e:	7f 2d                	jg     f010155d <vprintfmt+0x27e>
f0101530:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101533:	e9 d1 fd ff ff       	jmp    f0101309 <vprintfmt+0x2a>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101538:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010153b:	83 c1 01             	add    $0x1,%ecx
f010153e:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0101541:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101544:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f0101547:	89 cb                	mov    %ecx,%ebx
f0101549:	85 f6                	test   %esi,%esi
f010154b:	78 97                	js     f01014e4 <vprintfmt+0x205>
f010154d:	83 ee 01             	sub    $0x1,%esi
f0101550:	79 92                	jns    f01014e4 <vprintfmt+0x205>
f0101552:	89 7d dc             	mov    %edi,-0x24(%ebp)
f0101555:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101558:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010155b:	eb cd                	jmp    f010152a <vprintfmt+0x24b>
f010155d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101560:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101563:	8b 5d dc             	mov    -0x24(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101566:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010156a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101571:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101573:	83 eb 01             	sub    $0x1,%ebx
f0101576:	85 db                	test   %ebx,%ebx
f0101578:	7f ec                	jg     f0101566 <vprintfmt+0x287>
f010157a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010157d:	e9 87 fd ff ff       	jmp    f0101309 <vprintfmt+0x2a>
f0101582:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101585:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
f0101589:	88 45 e4             	mov    %al,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010158c:	83 7d d0 01          	cmpl   $0x1,-0x30(%ebp)
f0101590:	7e 16                	jle    f01015a8 <vprintfmt+0x2c9>
		return va_arg(*ap, long long);
f0101592:	8b 45 14             	mov    0x14(%ebp),%eax
f0101595:	8d 50 08             	lea    0x8(%eax),%edx
f0101598:	89 55 14             	mov    %edx,0x14(%ebp)
f010159b:	8b 10                	mov    (%eax),%edx
f010159d:	8b 48 04             	mov    0x4(%eax),%ecx
f01015a0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01015a3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01015a6:	eb 34                	jmp    f01015dc <vprintfmt+0x2fd>
	else if (lflag)
f01015a8:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01015ac:	74 18                	je     f01015c6 <vprintfmt+0x2e7>
		return va_arg(*ap, long);
f01015ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01015b1:	8d 50 04             	lea    0x4(%eax),%edx
f01015b4:	89 55 14             	mov    %edx,0x14(%ebp)
f01015b7:	8b 00                	mov    (%eax),%eax
f01015b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015bc:	89 c1                	mov    %eax,%ecx
f01015be:	c1 f9 1f             	sar    $0x1f,%ecx
f01015c1:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01015c4:	eb 16                	jmp    f01015dc <vprintfmt+0x2fd>
	else
		return va_arg(*ap, int);
f01015c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01015c9:	8d 50 04             	lea    0x4(%eax),%edx
f01015cc:	89 55 14             	mov    %edx,0x14(%ebp)
f01015cf:	8b 00                	mov    (%eax),%eax
f01015d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015d4:	89 c2                	mov    %eax,%edx
f01015d6:	c1 fa 1f             	sar    $0x1f,%edx
f01015d9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01015dc:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01015df:	8b 75 d4             	mov    -0x2c(%ebp),%esi
			if ((long long) num < 0) {
f01015e2:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01015e6:	79 2c                	jns    f0101614 <vprintfmt+0x335>
				putch('-', putdat);
f01015e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01015ec:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01015f3:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01015f6:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01015f9:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01015fc:	f7 db                	neg    %ebx
f01015fe:	83 d6 00             	adc    $0x0,%esi
f0101601:	f7 de                	neg    %esi
f0101603:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f0101607:	88 4d e4             	mov    %cl,-0x1c(%ebp)
f010160a:	ba 0a 00 00 00       	mov    $0xa,%edx
f010160f:	e9 db 00 00 00       	jmp    f01016ef <vprintfmt+0x410>
			}else if(padc == '+'){
f0101614:	80 7d e4 2b          	cmpb   $0x2b,-0x1c(%ebp)
f0101618:	74 11                	je     f010162b <vprintfmt+0x34c>
f010161a:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
f010161e:	88 45 e4             	mov    %al,-0x1c(%ebp)
f0101621:	ba 0a 00 00 00       	mov    $0xa,%edx
f0101626:	e9 c4 00 00 00       	jmp    f01016ef <vprintfmt+0x410>
				putch(padc, putdat);
f010162b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010162f:	c7 04 24 2b 00 00 00 	movl   $0x2b,(%esp)
f0101636:	ff 55 08             	call   *0x8(%ebp)
f0101639:	ba 0a 00 00 00       	mov    $0xa,%edx
f010163e:	e9 ac 00 00 00       	jmp    f01016ef <vprintfmt+0x410>
f0101643:	89 45 cc             	mov    %eax,-0x34(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101646:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101649:	8d 45 14             	lea    0x14(%ebp),%eax
f010164c:	e8 37 fc ff ff       	call   f0101288 <getuint>
f0101651:	89 c3                	mov    %eax,%ebx
f0101653:	89 d6                	mov    %edx,%esi
f0101655:	0f b6 55 e0          	movzbl -0x20(%ebp),%edx
f0101659:	88 55 e4             	mov    %dl,-0x1c(%ebp)
f010165c:	ba 0a 00 00 00       	mov    $0xa,%edx
			base = 10;
			goto number;
f0101661:	e9 89 00 00 00       	jmp    f01016ef <vprintfmt+0x410>
f0101666:	89 45 cc             	mov    %eax,-0x34(%ebp)
			putch('X', putdat);
			break;
			*/
			
			// solution for exercise-8
			putch('0', putdat);
f0101669:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010166d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101674:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
f0101677:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010167a:	8d 45 14             	lea    0x14(%ebp),%eax
f010167d:	e8 06 fc ff ff       	call   f0101288 <getuint>
f0101682:	89 c3                	mov    %eax,%ebx
f0101684:	89 d6                	mov    %edx,%esi
f0101686:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f010168a:	88 4d e4             	mov    %cl,-0x1c(%ebp)
f010168d:	ba 08 00 00 00       	mov    $0x8,%edx
			base = 8;
			goto number;
f0101692:	eb 5b                	jmp    f01016ef <vprintfmt+0x410>
f0101694:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
f0101697:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010169b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01016a2:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01016a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016a9:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01016b0:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01016b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01016b6:	8d 50 04             	lea    0x4(%eax),%edx
f01016b9:	89 55 14             	mov    %edx,0x14(%ebp)
f01016bc:	8b 18                	mov    (%eax),%ebx
f01016be:	be 00 00 00 00       	mov    $0x0,%esi
f01016c3:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
f01016c7:	88 45 e4             	mov    %al,-0x1c(%ebp)
f01016ca:	ba 10 00 00 00       	mov    $0x10,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01016cf:	eb 1e                	jmp    f01016ef <vprintfmt+0x410>
f01016d1:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01016d4:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01016d7:	8d 45 14             	lea    0x14(%ebp),%eax
f01016da:	e8 a9 fb ff ff       	call   f0101288 <getuint>
f01016df:	89 c3                	mov    %eax,%ebx
f01016e1:	89 d6                	mov    %edx,%esi
f01016e3:	0f b6 55 e0          	movzbl -0x20(%ebp),%edx
f01016e7:	88 55 e4             	mov    %dl,-0x1c(%ebp)
f01016ea:	ba 10 00 00 00       	mov    $0x10,%edx
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f01016ef:	0f be 45 e4          	movsbl -0x1c(%ebp),%eax
f01016f3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01016f7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01016fa:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01016fe:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101702:	89 1c 24             	mov    %ebx,(%esp)
f0101705:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101709:	89 fa                	mov    %edi,%edx
f010170b:	8b 45 08             	mov    0x8(%ebp),%eax
f010170e:	e8 ad f9 ff ff       	call   f01010c0 <printnum>
f0101713:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f0101716:	e9 ee fb ff ff       	jmp    f0101309 <vprintfmt+0x2a>
f010171b:	89 45 cc             	mov    %eax,-0x34(%ebp)
            const char *null_error = "\nerror! writing through NULL pointer! (%n argument)\n";
            const char *overflow_error = "\nwarning! The value %n argument pointed to has been overflowed!\n";

            // Your code here
			char* input_pos = putdat;
			char* extra_para = va_arg(ap, char*);
f010171e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101721:	8d 50 04             	lea    0x4(%eax),%edx
f0101724:	89 55 14             	mov    %edx,0x14(%ebp)
f0101727:	8b 18                	mov    (%eax),%ebx
			if (extra_para == NULL) {
f0101729:	85 db                	test   %ebx,%ebx
f010172b:	75 1c                	jne    f0101749 <vprintfmt+0x46a>
				cprintf("%s", null_error);
f010172d:	c7 44 24 04 e4 26 10 	movl   $0xf01026e4,0x4(%esp)
f0101734:	f0 
f0101735:	c7 04 24 6f 26 10 f0 	movl   $0xf010266f,(%esp)
f010173c:	e8 e2 f5 ff ff       	call   f0100d23 <cprintf>
f0101741:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101744:	e9 c0 fb ff ff       	jmp    f0101309 <vprintfmt+0x2a>
			}
			else if ((*input_pos) & 0x80){		// if > 127
f0101749:	0f b6 07             	movzbl (%edi),%eax
f010174c:	84 c0                	test   %al,%al
f010174e:	79 21                	jns    f0101771 <vprintfmt+0x492>
				cprintf("%s", overflow_error);
f0101750:	c7 44 24 04 1c 27 10 	movl   $0xf010271c,0x4(%esp)
f0101757:	f0 
f0101758:	c7 04 24 6f 26 10 f0 	movl   $0xf010266f,(%esp)
f010175f:	e8 bf f5 ff ff       	call   f0100d23 <cprintf>
				*extra_para = *input_pos;				// -1
f0101764:	0f b6 07             	movzbl (%edi),%eax
f0101767:	88 03                	mov    %al,(%ebx)
f0101769:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f010176c:	e9 98 fb ff ff       	jmp    f0101309 <vprintfmt+0x2a>
			}
			else {
				*extra_para = *input_pos;
f0101771:	88 03                	mov    %al,(%ebx)
f0101773:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101776:	e9 8e fb ff ff       	jmp    f0101309 <vprintfmt+0x2a>
f010177b:	89 45 cc             	mov    %eax,-0x34(%ebp)
            break;
        }

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010177e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101782:	89 14 24             	mov    %edx,(%esp)
f0101785:	ff 55 08             	call   *0x8(%ebp)
f0101788:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f010178b:	e9 79 fb ff ff       	jmp    f0101309 <vprintfmt+0x2a>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101790:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101794:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010179b:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010179e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01017a1:	80 38 25             	cmpb   $0x25,(%eax)
f01017a4:	0f 84 5f fb ff ff    	je     f0101309 <vprintfmt+0x2a>
f01017aa:	89 c3                	mov    %eax,%ebx
f01017ac:	eb f0                	jmp    f010179e <vprintfmt+0x4bf>
				/* do nothing */;
			break;
		}
	}
}
f01017ae:	83 c4 5c             	add    $0x5c,%esp
f01017b1:	5b                   	pop    %ebx
f01017b2:	5e                   	pop    %esi
f01017b3:	5f                   	pop    %edi
f01017b4:	5d                   	pop    %ebp
f01017b5:	c3                   	ret    

f01017b6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01017b6:	55                   	push   %ebp
f01017b7:	89 e5                	mov    %esp,%ebp
f01017b9:	83 ec 28             	sub    $0x28,%esp
f01017bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01017bf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f01017c2:	85 c0                	test   %eax,%eax
f01017c4:	74 04                	je     f01017ca <vsnprintf+0x14>
f01017c6:	85 d2                	test   %edx,%edx
f01017c8:	7f 07                	jg     f01017d1 <vsnprintf+0x1b>
f01017ca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01017cf:	eb 3b                	jmp    f010180c <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f01017d1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01017d4:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f01017d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01017db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01017e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01017e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017e9:	8b 45 10             	mov    0x10(%ebp),%eax
f01017ec:	89 44 24 08          	mov    %eax,0x8(%esp)
f01017f0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01017f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017f7:	c7 04 24 c2 12 10 f0 	movl   $0xf01012c2,(%esp)
f01017fe:	e8 dc fa ff ff       	call   f01012df <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101803:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101806:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101809:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010180c:	c9                   	leave  
f010180d:	c3                   	ret    

f010180e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010180e:	55                   	push   %ebp
f010180f:	89 e5                	mov    %esp,%ebp
f0101811:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f0101814:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0101817:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010181b:	8b 45 10             	mov    0x10(%ebp),%eax
f010181e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101822:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101825:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101829:	8b 45 08             	mov    0x8(%ebp),%eax
f010182c:	89 04 24             	mov    %eax,(%esp)
f010182f:	e8 82 ff ff ff       	call   f01017b6 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101834:	c9                   	leave  
f0101835:	c3                   	ret    

f0101836 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101836:	55                   	push   %ebp
f0101837:	89 e5                	mov    %esp,%ebp
f0101839:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f010183c:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f010183f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101843:	8b 45 10             	mov    0x10(%ebp),%eax
f0101846:	89 44 24 08          	mov    %eax,0x8(%esp)
f010184a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010184d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101851:	8b 45 08             	mov    0x8(%ebp),%eax
f0101854:	89 04 24             	mov    %eax,(%esp)
f0101857:	e8 83 fa ff ff       	call   f01012df <vprintfmt>
	va_end(ap);
}
f010185c:	c9                   	leave  
f010185d:	c3                   	ret    
	...

f0101860 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101860:	55                   	push   %ebp
f0101861:	89 e5                	mov    %esp,%ebp
f0101863:	57                   	push   %edi
f0101864:	56                   	push   %esi
f0101865:	53                   	push   %ebx
f0101866:	83 ec 1c             	sub    $0x1c,%esp
f0101869:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010186c:	85 c0                	test   %eax,%eax
f010186e:	74 10                	je     f0101880 <readline+0x20>
		cprintf("%s", prompt);
f0101870:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101874:	c7 04 24 6f 26 10 f0 	movl   $0xf010266f,(%esp)
f010187b:	e8 a3 f4 ff ff       	call   f0100d23 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101880:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101887:	e8 fa ea ff ff       	call   f0100386 <iscons>
f010188c:	89 c7                	mov    %eax,%edi
f010188e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101893:	e8 dd ea ff ff       	call   f0100375 <getchar>
f0101898:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010189a:	85 c0                	test   %eax,%eax
f010189c:	79 17                	jns    f01018b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010189e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a2:	c7 04 24 d4 28 10 f0 	movl   $0xf01028d4,(%esp)
f01018a9:	e8 75 f4 ff ff       	call   f0100d23 <cprintf>
f01018ae:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f01018b3:	eb 76                	jmp    f010192b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01018b5:	83 f8 08             	cmp    $0x8,%eax
f01018b8:	74 08                	je     f01018c2 <readline+0x62>
f01018ba:	83 f8 7f             	cmp    $0x7f,%eax
f01018bd:	8d 76 00             	lea    0x0(%esi),%esi
f01018c0:	75 19                	jne    f01018db <readline+0x7b>
f01018c2:	85 f6                	test   %esi,%esi
f01018c4:	7e 15                	jle    f01018db <readline+0x7b>
			if (echoing)
f01018c6:	85 ff                	test   %edi,%edi
f01018c8:	74 0c                	je     f01018d6 <readline+0x76>
				cputchar('\b');
f01018ca:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01018d1:	e8 b4 ec ff ff       	call   f010058a <cputchar>
			i--;
f01018d6:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01018d9:	eb b8                	jmp    f0101893 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01018db:	83 fb 1f             	cmp    $0x1f,%ebx
f01018de:	66 90                	xchg   %ax,%ax
f01018e0:	7e 23                	jle    f0101905 <readline+0xa5>
f01018e2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01018e8:	7f 1b                	jg     f0101905 <readline+0xa5>
			if (echoing)
f01018ea:	85 ff                	test   %edi,%edi
f01018ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018f0:	74 08                	je     f01018fa <readline+0x9a>
				cputchar(c);
f01018f2:	89 1c 24             	mov    %ebx,(%esp)
f01018f5:	e8 90 ec ff ff       	call   f010058a <cputchar>
			buf[i++] = c;
f01018fa:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101900:	83 c6 01             	add    $0x1,%esi
f0101903:	eb 8e                	jmp    f0101893 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101905:	83 fb 0a             	cmp    $0xa,%ebx
f0101908:	74 05                	je     f010190f <readline+0xaf>
f010190a:	83 fb 0d             	cmp    $0xd,%ebx
f010190d:	75 84                	jne    f0101893 <readline+0x33>
			if (echoing)
f010190f:	85 ff                	test   %edi,%edi
f0101911:	74 0c                	je     f010191f <readline+0xbf>
				cputchar('\n');
f0101913:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010191a:	e8 6b ec ff ff       	call   f010058a <cputchar>
			buf[i] = 0;
f010191f:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
f0101926:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
			return buf;
		}
	}
}
f010192b:	83 c4 1c             	add    $0x1c,%esp
f010192e:	5b                   	pop    %ebx
f010192f:	5e                   	pop    %esi
f0101930:	5f                   	pop    %edi
f0101931:	5d                   	pop    %ebp
f0101932:	c3                   	ret    
	...

f0101940 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101940:	55                   	push   %ebp
f0101941:	89 e5                	mov    %esp,%ebp
f0101943:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101946:	b8 00 00 00 00       	mov    $0x0,%eax
f010194b:	80 3a 00             	cmpb   $0x0,(%edx)
f010194e:	74 09                	je     f0101959 <strlen+0x19>
		n++;
f0101950:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101953:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101957:	75 f7                	jne    f0101950 <strlen+0x10>
		n++;
	return n;
}
f0101959:	5d                   	pop    %ebp
f010195a:	c3                   	ret    

f010195b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010195b:	55                   	push   %ebp
f010195c:	89 e5                	mov    %esp,%ebp
f010195e:	53                   	push   %ebx
f010195f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101962:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101965:	85 c9                	test   %ecx,%ecx
f0101967:	74 19                	je     f0101982 <strnlen+0x27>
f0101969:	80 3b 00             	cmpb   $0x0,(%ebx)
f010196c:	74 14                	je     f0101982 <strnlen+0x27>
f010196e:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101973:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101976:	39 c8                	cmp    %ecx,%eax
f0101978:	74 0d                	je     f0101987 <strnlen+0x2c>
f010197a:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f010197e:	75 f3                	jne    f0101973 <strnlen+0x18>
f0101980:	eb 05                	jmp    f0101987 <strnlen+0x2c>
f0101982:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101987:	5b                   	pop    %ebx
f0101988:	5d                   	pop    %ebp
f0101989:	c3                   	ret    

f010198a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010198a:	55                   	push   %ebp
f010198b:	89 e5                	mov    %esp,%ebp
f010198d:	53                   	push   %ebx
f010198e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101991:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101994:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101999:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010199d:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01019a0:	83 c2 01             	add    $0x1,%edx
f01019a3:	84 c9                	test   %cl,%cl
f01019a5:	75 f2                	jne    f0101999 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01019a7:	5b                   	pop    %ebx
f01019a8:	5d                   	pop    %ebp
f01019a9:	c3                   	ret    

f01019aa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01019aa:	55                   	push   %ebp
f01019ab:	89 e5                	mov    %esp,%ebp
f01019ad:	56                   	push   %esi
f01019ae:	53                   	push   %ebx
f01019af:	8b 45 08             	mov    0x8(%ebp),%eax
f01019b2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019b5:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01019b8:	85 f6                	test   %esi,%esi
f01019ba:	74 18                	je     f01019d4 <strncpy+0x2a>
f01019bc:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01019c1:	0f b6 1a             	movzbl (%edx),%ebx
f01019c4:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01019c7:	80 3a 01             	cmpb   $0x1,(%edx)
f01019ca:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01019cd:	83 c1 01             	add    $0x1,%ecx
f01019d0:	39 ce                	cmp    %ecx,%esi
f01019d2:	77 ed                	ja     f01019c1 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01019d4:	5b                   	pop    %ebx
f01019d5:	5e                   	pop    %esi
f01019d6:	5d                   	pop    %ebp
f01019d7:	c3                   	ret    

f01019d8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01019d8:	55                   	push   %ebp
f01019d9:	89 e5                	mov    %esp,%ebp
f01019db:	56                   	push   %esi
f01019dc:	53                   	push   %ebx
f01019dd:	8b 75 08             	mov    0x8(%ebp),%esi
f01019e0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019e3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01019e6:	89 f0                	mov    %esi,%eax
f01019e8:	85 c9                	test   %ecx,%ecx
f01019ea:	74 27                	je     f0101a13 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f01019ec:	83 e9 01             	sub    $0x1,%ecx
f01019ef:	74 1d                	je     f0101a0e <strlcpy+0x36>
f01019f1:	0f b6 1a             	movzbl (%edx),%ebx
f01019f4:	84 db                	test   %bl,%bl
f01019f6:	74 16                	je     f0101a0e <strlcpy+0x36>
			*dst++ = *src++;
f01019f8:	88 18                	mov    %bl,(%eax)
f01019fa:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01019fd:	83 e9 01             	sub    $0x1,%ecx
f0101a00:	74 0e                	je     f0101a10 <strlcpy+0x38>
			*dst++ = *src++;
f0101a02:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101a05:	0f b6 1a             	movzbl (%edx),%ebx
f0101a08:	84 db                	test   %bl,%bl
f0101a0a:	75 ec                	jne    f01019f8 <strlcpy+0x20>
f0101a0c:	eb 02                	jmp    f0101a10 <strlcpy+0x38>
f0101a0e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101a10:	c6 00 00             	movb   $0x0,(%eax)
f0101a13:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101a15:	5b                   	pop    %ebx
f0101a16:	5e                   	pop    %esi
f0101a17:	5d                   	pop    %ebp
f0101a18:	c3                   	ret    

f0101a19 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101a19:	55                   	push   %ebp
f0101a1a:	89 e5                	mov    %esp,%ebp
f0101a1c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101a1f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101a22:	0f b6 01             	movzbl (%ecx),%eax
f0101a25:	84 c0                	test   %al,%al
f0101a27:	74 15                	je     f0101a3e <strcmp+0x25>
f0101a29:	3a 02                	cmp    (%edx),%al
f0101a2b:	75 11                	jne    f0101a3e <strcmp+0x25>
		p++, q++;
f0101a2d:	83 c1 01             	add    $0x1,%ecx
f0101a30:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101a33:	0f b6 01             	movzbl (%ecx),%eax
f0101a36:	84 c0                	test   %al,%al
f0101a38:	74 04                	je     f0101a3e <strcmp+0x25>
f0101a3a:	3a 02                	cmp    (%edx),%al
f0101a3c:	74 ef                	je     f0101a2d <strcmp+0x14>
f0101a3e:	0f b6 c0             	movzbl %al,%eax
f0101a41:	0f b6 12             	movzbl (%edx),%edx
f0101a44:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101a46:	5d                   	pop    %ebp
f0101a47:	c3                   	ret    

f0101a48 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101a48:	55                   	push   %ebp
f0101a49:	89 e5                	mov    %esp,%ebp
f0101a4b:	53                   	push   %ebx
f0101a4c:	8b 55 08             	mov    0x8(%ebp),%edx
f0101a4f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101a52:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f0101a55:	85 c0                	test   %eax,%eax
f0101a57:	74 23                	je     f0101a7c <strncmp+0x34>
f0101a59:	0f b6 1a             	movzbl (%edx),%ebx
f0101a5c:	84 db                	test   %bl,%bl
f0101a5e:	74 24                	je     f0101a84 <strncmp+0x3c>
f0101a60:	3a 19                	cmp    (%ecx),%bl
f0101a62:	75 20                	jne    f0101a84 <strncmp+0x3c>
f0101a64:	83 e8 01             	sub    $0x1,%eax
f0101a67:	74 13                	je     f0101a7c <strncmp+0x34>
		n--, p++, q++;
f0101a69:	83 c2 01             	add    $0x1,%edx
f0101a6c:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101a6f:	0f b6 1a             	movzbl (%edx),%ebx
f0101a72:	84 db                	test   %bl,%bl
f0101a74:	74 0e                	je     f0101a84 <strncmp+0x3c>
f0101a76:	3a 19                	cmp    (%ecx),%bl
f0101a78:	74 ea                	je     f0101a64 <strncmp+0x1c>
f0101a7a:	eb 08                	jmp    f0101a84 <strncmp+0x3c>
f0101a7c:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101a81:	5b                   	pop    %ebx
f0101a82:	5d                   	pop    %ebp
f0101a83:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a84:	0f b6 02             	movzbl (%edx),%eax
f0101a87:	0f b6 11             	movzbl (%ecx),%edx
f0101a8a:	29 d0                	sub    %edx,%eax
f0101a8c:	eb f3                	jmp    f0101a81 <strncmp+0x39>

f0101a8e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101a8e:	55                   	push   %ebp
f0101a8f:	89 e5                	mov    %esp,%ebp
f0101a91:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a94:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101a98:	0f b6 10             	movzbl (%eax),%edx
f0101a9b:	84 d2                	test   %dl,%dl
f0101a9d:	74 15                	je     f0101ab4 <strchr+0x26>
		if (*s == c)
f0101a9f:	38 ca                	cmp    %cl,%dl
f0101aa1:	75 07                	jne    f0101aaa <strchr+0x1c>
f0101aa3:	eb 14                	jmp    f0101ab9 <strchr+0x2b>
f0101aa5:	38 ca                	cmp    %cl,%dl
f0101aa7:	90                   	nop
f0101aa8:	74 0f                	je     f0101ab9 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101aaa:	83 c0 01             	add    $0x1,%eax
f0101aad:	0f b6 10             	movzbl (%eax),%edx
f0101ab0:	84 d2                	test   %dl,%dl
f0101ab2:	75 f1                	jne    f0101aa5 <strchr+0x17>
f0101ab4:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f0101ab9:	5d                   	pop    %ebp
f0101aba:	c3                   	ret    

f0101abb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101abb:	55                   	push   %ebp
f0101abc:	89 e5                	mov    %esp,%ebp
f0101abe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ac1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101ac5:	0f b6 10             	movzbl (%eax),%edx
f0101ac8:	84 d2                	test   %dl,%dl
f0101aca:	74 18                	je     f0101ae4 <strfind+0x29>
		if (*s == c)
f0101acc:	38 ca                	cmp    %cl,%dl
f0101ace:	75 0a                	jne    f0101ada <strfind+0x1f>
f0101ad0:	eb 12                	jmp    f0101ae4 <strfind+0x29>
f0101ad2:	38 ca                	cmp    %cl,%dl
f0101ad4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ad8:	74 0a                	je     f0101ae4 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101ada:	83 c0 01             	add    $0x1,%eax
f0101add:	0f b6 10             	movzbl (%eax),%edx
f0101ae0:	84 d2                	test   %dl,%dl
f0101ae2:	75 ee                	jne    f0101ad2 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101ae4:	5d                   	pop    %ebp
f0101ae5:	c3                   	ret    

f0101ae6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101ae6:	55                   	push   %ebp
f0101ae7:	89 e5                	mov    %esp,%ebp
f0101ae9:	83 ec 0c             	sub    $0xc,%esp
f0101aec:	89 1c 24             	mov    %ebx,(%esp)
f0101aef:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101af3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101af7:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101afa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101afd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101b00:	85 c9                	test   %ecx,%ecx
f0101b02:	74 30                	je     f0101b34 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101b04:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101b0a:	75 25                	jne    f0101b31 <memset+0x4b>
f0101b0c:	f6 c1 03             	test   $0x3,%cl
f0101b0f:	75 20                	jne    f0101b31 <memset+0x4b>
		c &= 0xFF;
f0101b11:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101b14:	89 d3                	mov    %edx,%ebx
f0101b16:	c1 e3 08             	shl    $0x8,%ebx
f0101b19:	89 d6                	mov    %edx,%esi
f0101b1b:	c1 e6 18             	shl    $0x18,%esi
f0101b1e:	89 d0                	mov    %edx,%eax
f0101b20:	c1 e0 10             	shl    $0x10,%eax
f0101b23:	09 f0                	or     %esi,%eax
f0101b25:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101b27:	09 d8                	or     %ebx,%eax
f0101b29:	c1 e9 02             	shr    $0x2,%ecx
f0101b2c:	fc                   	cld    
f0101b2d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101b2f:	eb 03                	jmp    f0101b34 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101b31:	fc                   	cld    
f0101b32:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101b34:	89 f8                	mov    %edi,%eax
f0101b36:	8b 1c 24             	mov    (%esp),%ebx
f0101b39:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101b3d:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101b41:	89 ec                	mov    %ebp,%esp
f0101b43:	5d                   	pop    %ebp
f0101b44:	c3                   	ret    

f0101b45 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101b45:	55                   	push   %ebp
f0101b46:	89 e5                	mov    %esp,%ebp
f0101b48:	83 ec 08             	sub    $0x8,%esp
f0101b4b:	89 34 24             	mov    %esi,(%esp)
f0101b4e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101b52:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b55:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f0101b58:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f0101b5b:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f0101b5d:	39 c6                	cmp    %eax,%esi
f0101b5f:	73 35                	jae    f0101b96 <memmove+0x51>
f0101b61:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101b64:	39 d0                	cmp    %edx,%eax
f0101b66:	73 2e                	jae    f0101b96 <memmove+0x51>
		s += n;
		d += n;
f0101b68:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101b6a:	f6 c2 03             	test   $0x3,%dl
f0101b6d:	75 1b                	jne    f0101b8a <memmove+0x45>
f0101b6f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101b75:	75 13                	jne    f0101b8a <memmove+0x45>
f0101b77:	f6 c1 03             	test   $0x3,%cl
f0101b7a:	75 0e                	jne    f0101b8a <memmove+0x45>
			asm volatile("std; rep movsl\n"
f0101b7c:	83 ef 04             	sub    $0x4,%edi
f0101b7f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101b82:	c1 e9 02             	shr    $0x2,%ecx
f0101b85:	fd                   	std    
f0101b86:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101b88:	eb 09                	jmp    f0101b93 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101b8a:	83 ef 01             	sub    $0x1,%edi
f0101b8d:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101b90:	fd                   	std    
f0101b91:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101b93:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101b94:	eb 20                	jmp    f0101bb6 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101b96:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101b9c:	75 15                	jne    f0101bb3 <memmove+0x6e>
f0101b9e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101ba4:	75 0d                	jne    f0101bb3 <memmove+0x6e>
f0101ba6:	f6 c1 03             	test   $0x3,%cl
f0101ba9:	75 08                	jne    f0101bb3 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f0101bab:	c1 e9 02             	shr    $0x2,%ecx
f0101bae:	fc                   	cld    
f0101baf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101bb1:	eb 03                	jmp    f0101bb6 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101bb3:	fc                   	cld    
f0101bb4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101bb6:	8b 34 24             	mov    (%esp),%esi
f0101bb9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101bbd:	89 ec                	mov    %ebp,%esp
f0101bbf:	5d                   	pop    %ebp
f0101bc0:	c3                   	ret    

f0101bc1 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101bc1:	55                   	push   %ebp
f0101bc2:	89 e5                	mov    %esp,%ebp
f0101bc4:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101bc7:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bce:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bd1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101bd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bd8:	89 04 24             	mov    %eax,(%esp)
f0101bdb:	e8 65 ff ff ff       	call   f0101b45 <memmove>
}
f0101be0:	c9                   	leave  
f0101be1:	c3                   	ret    

f0101be2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101be2:	55                   	push   %ebp
f0101be3:	89 e5                	mov    %esp,%ebp
f0101be5:	57                   	push   %edi
f0101be6:	56                   	push   %esi
f0101be7:	53                   	push   %ebx
f0101be8:	8b 75 08             	mov    0x8(%ebp),%esi
f0101beb:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101bee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101bf1:	85 c9                	test   %ecx,%ecx
f0101bf3:	74 36                	je     f0101c2b <memcmp+0x49>
		if (*s1 != *s2)
f0101bf5:	0f b6 06             	movzbl (%esi),%eax
f0101bf8:	0f b6 1f             	movzbl (%edi),%ebx
f0101bfb:	38 d8                	cmp    %bl,%al
f0101bfd:	74 20                	je     f0101c1f <memcmp+0x3d>
f0101bff:	eb 14                	jmp    f0101c15 <memcmp+0x33>
f0101c01:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101c06:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f0101c0b:	83 c2 01             	add    $0x1,%edx
f0101c0e:	83 e9 01             	sub    $0x1,%ecx
f0101c11:	38 d8                	cmp    %bl,%al
f0101c13:	74 12                	je     f0101c27 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101c15:	0f b6 c0             	movzbl %al,%eax
f0101c18:	0f b6 db             	movzbl %bl,%ebx
f0101c1b:	29 d8                	sub    %ebx,%eax
f0101c1d:	eb 11                	jmp    f0101c30 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101c1f:	83 e9 01             	sub    $0x1,%ecx
f0101c22:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c27:	85 c9                	test   %ecx,%ecx
f0101c29:	75 d6                	jne    f0101c01 <memcmp+0x1f>
f0101c2b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f0101c30:	5b                   	pop    %ebx
f0101c31:	5e                   	pop    %esi
f0101c32:	5f                   	pop    %edi
f0101c33:	5d                   	pop    %ebp
f0101c34:	c3                   	ret    

f0101c35 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101c35:	55                   	push   %ebp
f0101c36:	89 e5                	mov    %esp,%ebp
f0101c38:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101c3b:	89 c2                	mov    %eax,%edx
f0101c3d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101c40:	39 d0                	cmp    %edx,%eax
f0101c42:	73 15                	jae    f0101c59 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101c44:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101c48:	38 08                	cmp    %cl,(%eax)
f0101c4a:	75 06                	jne    f0101c52 <memfind+0x1d>
f0101c4c:	eb 0b                	jmp    f0101c59 <memfind+0x24>
f0101c4e:	38 08                	cmp    %cl,(%eax)
f0101c50:	74 07                	je     f0101c59 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101c52:	83 c0 01             	add    $0x1,%eax
f0101c55:	39 c2                	cmp    %eax,%edx
f0101c57:	77 f5                	ja     f0101c4e <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101c59:	5d                   	pop    %ebp
f0101c5a:	c3                   	ret    

f0101c5b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101c5b:	55                   	push   %ebp
f0101c5c:	89 e5                	mov    %esp,%ebp
f0101c5e:	57                   	push   %edi
f0101c5f:	56                   	push   %esi
f0101c60:	53                   	push   %ebx
f0101c61:	83 ec 04             	sub    $0x4,%esp
f0101c64:	8b 55 08             	mov    0x8(%ebp),%edx
f0101c67:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101c6a:	0f b6 02             	movzbl (%edx),%eax
f0101c6d:	3c 20                	cmp    $0x20,%al
f0101c6f:	74 04                	je     f0101c75 <strtol+0x1a>
f0101c71:	3c 09                	cmp    $0x9,%al
f0101c73:	75 0e                	jne    f0101c83 <strtol+0x28>
		s++;
f0101c75:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101c78:	0f b6 02             	movzbl (%edx),%eax
f0101c7b:	3c 20                	cmp    $0x20,%al
f0101c7d:	74 f6                	je     f0101c75 <strtol+0x1a>
f0101c7f:	3c 09                	cmp    $0x9,%al
f0101c81:	74 f2                	je     f0101c75 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101c83:	3c 2b                	cmp    $0x2b,%al
f0101c85:	75 0c                	jne    f0101c93 <strtol+0x38>
		s++;
f0101c87:	83 c2 01             	add    $0x1,%edx
f0101c8a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0101c91:	eb 15                	jmp    f0101ca8 <strtol+0x4d>
	else if (*s == '-')
f0101c93:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0101c9a:	3c 2d                	cmp    $0x2d,%al
f0101c9c:	75 0a                	jne    f0101ca8 <strtol+0x4d>
		s++, neg = 1;
f0101c9e:	83 c2 01             	add    $0x1,%edx
f0101ca1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101ca8:	85 db                	test   %ebx,%ebx
f0101caa:	0f 94 c0             	sete   %al
f0101cad:	74 05                	je     f0101cb4 <strtol+0x59>
f0101caf:	83 fb 10             	cmp    $0x10,%ebx
f0101cb2:	75 18                	jne    f0101ccc <strtol+0x71>
f0101cb4:	80 3a 30             	cmpb   $0x30,(%edx)
f0101cb7:	75 13                	jne    f0101ccc <strtol+0x71>
f0101cb9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101cbd:	8d 76 00             	lea    0x0(%esi),%esi
f0101cc0:	75 0a                	jne    f0101ccc <strtol+0x71>
		s += 2, base = 16;
f0101cc2:	83 c2 02             	add    $0x2,%edx
f0101cc5:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101cca:	eb 15                	jmp    f0101ce1 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101ccc:	84 c0                	test   %al,%al
f0101cce:	66 90                	xchg   %ax,%ax
f0101cd0:	74 0f                	je     f0101ce1 <strtol+0x86>
f0101cd2:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101cd7:	80 3a 30             	cmpb   $0x30,(%edx)
f0101cda:	75 05                	jne    f0101ce1 <strtol+0x86>
		s++, base = 8;
f0101cdc:	83 c2 01             	add    $0x1,%edx
f0101cdf:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101ce1:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ce6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101ce8:	0f b6 0a             	movzbl (%edx),%ecx
f0101ceb:	89 cf                	mov    %ecx,%edi
f0101ced:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101cf0:	80 fb 09             	cmp    $0x9,%bl
f0101cf3:	77 08                	ja     f0101cfd <strtol+0xa2>
			dig = *s - '0';
f0101cf5:	0f be c9             	movsbl %cl,%ecx
f0101cf8:	83 e9 30             	sub    $0x30,%ecx
f0101cfb:	eb 1e                	jmp    f0101d1b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f0101cfd:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101d00:	80 fb 19             	cmp    $0x19,%bl
f0101d03:	77 08                	ja     f0101d0d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101d05:	0f be c9             	movsbl %cl,%ecx
f0101d08:	83 e9 57             	sub    $0x57,%ecx
f0101d0b:	eb 0e                	jmp    f0101d1b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f0101d0d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101d10:	80 fb 19             	cmp    $0x19,%bl
f0101d13:	77 15                	ja     f0101d2a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101d15:	0f be c9             	movsbl %cl,%ecx
f0101d18:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101d1b:	39 f1                	cmp    %esi,%ecx
f0101d1d:	7d 0b                	jge    f0101d2a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f0101d1f:	83 c2 01             	add    $0x1,%edx
f0101d22:	0f af c6             	imul   %esi,%eax
f0101d25:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101d28:	eb be                	jmp    f0101ce8 <strtol+0x8d>
f0101d2a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0101d2c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101d30:	74 05                	je     f0101d37 <strtol+0xdc>
		*endptr = (char *) s;
f0101d32:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101d35:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101d37:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101d3b:	74 04                	je     f0101d41 <strtol+0xe6>
f0101d3d:	89 c8                	mov    %ecx,%eax
f0101d3f:	f7 d8                	neg    %eax
}
f0101d41:	83 c4 04             	add    $0x4,%esp
f0101d44:	5b                   	pop    %ebx
f0101d45:	5e                   	pop    %esi
f0101d46:	5f                   	pop    %edi
f0101d47:	5d                   	pop    %ebp
f0101d48:	c3                   	ret    
f0101d49:	00 00                	add    %al,(%eax)
f0101d4b:	00 00                	add    %al,(%eax)
f0101d4d:	00 00                	add    %al,(%eax)
	...

f0101d50 <__udivdi3>:
f0101d50:	55                   	push   %ebp
f0101d51:	89 e5                	mov    %esp,%ebp
f0101d53:	57                   	push   %edi
f0101d54:	56                   	push   %esi
f0101d55:	83 ec 10             	sub    $0x10,%esp
f0101d58:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d5b:	8b 55 08             	mov    0x8(%ebp),%edx
f0101d5e:	8b 75 10             	mov    0x10(%ebp),%esi
f0101d61:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101d64:	85 c0                	test   %eax,%eax
f0101d66:	89 55 f0             	mov    %edx,-0x10(%ebp)
f0101d69:	75 35                	jne    f0101da0 <__udivdi3+0x50>
f0101d6b:	39 fe                	cmp    %edi,%esi
f0101d6d:	77 61                	ja     f0101dd0 <__udivdi3+0x80>
f0101d6f:	85 f6                	test   %esi,%esi
f0101d71:	75 0b                	jne    f0101d7e <__udivdi3+0x2e>
f0101d73:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d78:	31 d2                	xor    %edx,%edx
f0101d7a:	f7 f6                	div    %esi
f0101d7c:	89 c6                	mov    %eax,%esi
f0101d7e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0101d81:	31 d2                	xor    %edx,%edx
f0101d83:	89 f8                	mov    %edi,%eax
f0101d85:	f7 f6                	div    %esi
f0101d87:	89 c7                	mov    %eax,%edi
f0101d89:	89 c8                	mov    %ecx,%eax
f0101d8b:	f7 f6                	div    %esi
f0101d8d:	89 c1                	mov    %eax,%ecx
f0101d8f:	89 fa                	mov    %edi,%edx
f0101d91:	89 c8                	mov    %ecx,%eax
f0101d93:	83 c4 10             	add    $0x10,%esp
f0101d96:	5e                   	pop    %esi
f0101d97:	5f                   	pop    %edi
f0101d98:	5d                   	pop    %ebp
f0101d99:	c3                   	ret    
f0101d9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101da0:	39 f8                	cmp    %edi,%eax
f0101da2:	77 1c                	ja     f0101dc0 <__udivdi3+0x70>
f0101da4:	0f bd d0             	bsr    %eax,%edx
f0101da7:	83 f2 1f             	xor    $0x1f,%edx
f0101daa:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101dad:	75 39                	jne    f0101de8 <__udivdi3+0x98>
f0101daf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101db2:	0f 86 a0 00 00 00    	jbe    f0101e58 <__udivdi3+0x108>
f0101db8:	39 f8                	cmp    %edi,%eax
f0101dba:	0f 82 98 00 00 00    	jb     f0101e58 <__udivdi3+0x108>
f0101dc0:	31 ff                	xor    %edi,%edi
f0101dc2:	31 c9                	xor    %ecx,%ecx
f0101dc4:	89 c8                	mov    %ecx,%eax
f0101dc6:	89 fa                	mov    %edi,%edx
f0101dc8:	83 c4 10             	add    $0x10,%esp
f0101dcb:	5e                   	pop    %esi
f0101dcc:	5f                   	pop    %edi
f0101dcd:	5d                   	pop    %ebp
f0101dce:	c3                   	ret    
f0101dcf:	90                   	nop
f0101dd0:	89 d1                	mov    %edx,%ecx
f0101dd2:	89 fa                	mov    %edi,%edx
f0101dd4:	89 c8                	mov    %ecx,%eax
f0101dd6:	31 ff                	xor    %edi,%edi
f0101dd8:	f7 f6                	div    %esi
f0101dda:	89 c1                	mov    %eax,%ecx
f0101ddc:	89 fa                	mov    %edi,%edx
f0101dde:	89 c8                	mov    %ecx,%eax
f0101de0:	83 c4 10             	add    $0x10,%esp
f0101de3:	5e                   	pop    %esi
f0101de4:	5f                   	pop    %edi
f0101de5:	5d                   	pop    %ebp
f0101de6:	c3                   	ret    
f0101de7:	90                   	nop
f0101de8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101dec:	89 f2                	mov    %esi,%edx
f0101dee:	d3 e0                	shl    %cl,%eax
f0101df0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101df3:	b8 20 00 00 00       	mov    $0x20,%eax
f0101df8:	2b 45 f4             	sub    -0xc(%ebp),%eax
f0101dfb:	89 c1                	mov    %eax,%ecx
f0101dfd:	d3 ea                	shr    %cl,%edx
f0101dff:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101e03:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101e06:	d3 e6                	shl    %cl,%esi
f0101e08:	89 c1                	mov    %eax,%ecx
f0101e0a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f0101e0d:	89 fe                	mov    %edi,%esi
f0101e0f:	d3 ee                	shr    %cl,%esi
f0101e11:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101e15:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101e18:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101e1b:	d3 e7                	shl    %cl,%edi
f0101e1d:	89 c1                	mov    %eax,%ecx
f0101e1f:	d3 ea                	shr    %cl,%edx
f0101e21:	09 d7                	or     %edx,%edi
f0101e23:	89 f2                	mov    %esi,%edx
f0101e25:	89 f8                	mov    %edi,%eax
f0101e27:	f7 75 ec             	divl   -0x14(%ebp)
f0101e2a:	89 d6                	mov    %edx,%esi
f0101e2c:	89 c7                	mov    %eax,%edi
f0101e2e:	f7 65 e8             	mull   -0x18(%ebp)
f0101e31:	39 d6                	cmp    %edx,%esi
f0101e33:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101e36:	72 30                	jb     f0101e68 <__udivdi3+0x118>
f0101e38:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101e3b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101e3f:	d3 e2                	shl    %cl,%edx
f0101e41:	39 c2                	cmp    %eax,%edx
f0101e43:	73 05                	jae    f0101e4a <__udivdi3+0xfa>
f0101e45:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f0101e48:	74 1e                	je     f0101e68 <__udivdi3+0x118>
f0101e4a:	89 f9                	mov    %edi,%ecx
f0101e4c:	31 ff                	xor    %edi,%edi
f0101e4e:	e9 71 ff ff ff       	jmp    f0101dc4 <__udivdi3+0x74>
f0101e53:	90                   	nop
f0101e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e58:	31 ff                	xor    %edi,%edi
f0101e5a:	b9 01 00 00 00       	mov    $0x1,%ecx
f0101e5f:	e9 60 ff ff ff       	jmp    f0101dc4 <__udivdi3+0x74>
f0101e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e68:	8d 4f ff             	lea    -0x1(%edi),%ecx
f0101e6b:	31 ff                	xor    %edi,%edi
f0101e6d:	89 c8                	mov    %ecx,%eax
f0101e6f:	89 fa                	mov    %edi,%edx
f0101e71:	83 c4 10             	add    $0x10,%esp
f0101e74:	5e                   	pop    %esi
f0101e75:	5f                   	pop    %edi
f0101e76:	5d                   	pop    %ebp
f0101e77:	c3                   	ret    
	...

f0101e80 <__umoddi3>:
f0101e80:	55                   	push   %ebp
f0101e81:	89 e5                	mov    %esp,%ebp
f0101e83:	57                   	push   %edi
f0101e84:	56                   	push   %esi
f0101e85:	83 ec 20             	sub    $0x20,%esp
f0101e88:	8b 55 14             	mov    0x14(%ebp),%edx
f0101e8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e8e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101e91:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101e94:	85 d2                	test   %edx,%edx
f0101e96:	89 c8                	mov    %ecx,%eax
f0101e98:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f0101e9b:	75 13                	jne    f0101eb0 <__umoddi3+0x30>
f0101e9d:	39 f7                	cmp    %esi,%edi
f0101e9f:	76 3f                	jbe    f0101ee0 <__umoddi3+0x60>
f0101ea1:	89 f2                	mov    %esi,%edx
f0101ea3:	f7 f7                	div    %edi
f0101ea5:	89 d0                	mov    %edx,%eax
f0101ea7:	31 d2                	xor    %edx,%edx
f0101ea9:	83 c4 20             	add    $0x20,%esp
f0101eac:	5e                   	pop    %esi
f0101ead:	5f                   	pop    %edi
f0101eae:	5d                   	pop    %ebp
f0101eaf:	c3                   	ret    
f0101eb0:	39 f2                	cmp    %esi,%edx
f0101eb2:	77 4c                	ja     f0101f00 <__umoddi3+0x80>
f0101eb4:	0f bd ca             	bsr    %edx,%ecx
f0101eb7:	83 f1 1f             	xor    $0x1f,%ecx
f0101eba:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101ebd:	75 51                	jne    f0101f10 <__umoddi3+0x90>
f0101ebf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101ec2:	0f 87 e0 00 00 00    	ja     f0101fa8 <__umoddi3+0x128>
f0101ec8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101ecb:	29 f8                	sub    %edi,%eax
f0101ecd:	19 d6                	sbb    %edx,%esi
f0101ecf:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101ed2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101ed5:	89 f2                	mov    %esi,%edx
f0101ed7:	83 c4 20             	add    $0x20,%esp
f0101eda:	5e                   	pop    %esi
f0101edb:	5f                   	pop    %edi
f0101edc:	5d                   	pop    %ebp
f0101edd:	c3                   	ret    
f0101ede:	66 90                	xchg   %ax,%ax
f0101ee0:	85 ff                	test   %edi,%edi
f0101ee2:	75 0b                	jne    f0101eef <__umoddi3+0x6f>
f0101ee4:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ee9:	31 d2                	xor    %edx,%edx
f0101eeb:	f7 f7                	div    %edi
f0101eed:	89 c7                	mov    %eax,%edi
f0101eef:	89 f0                	mov    %esi,%eax
f0101ef1:	31 d2                	xor    %edx,%edx
f0101ef3:	f7 f7                	div    %edi
f0101ef5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101ef8:	f7 f7                	div    %edi
f0101efa:	eb a9                	jmp    f0101ea5 <__umoddi3+0x25>
f0101efc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f00:	89 c8                	mov    %ecx,%eax
f0101f02:	89 f2                	mov    %esi,%edx
f0101f04:	83 c4 20             	add    $0x20,%esp
f0101f07:	5e                   	pop    %esi
f0101f08:	5f                   	pop    %edi
f0101f09:	5d                   	pop    %ebp
f0101f0a:	c3                   	ret    
f0101f0b:	90                   	nop
f0101f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f10:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101f14:	d3 e2                	shl    %cl,%edx
f0101f16:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101f19:	ba 20 00 00 00       	mov    $0x20,%edx
f0101f1e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101f21:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101f24:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101f28:	89 fa                	mov    %edi,%edx
f0101f2a:	d3 ea                	shr    %cl,%edx
f0101f2c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101f30:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101f33:	d3 e7                	shl    %cl,%edi
f0101f35:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101f39:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101f3c:	89 f2                	mov    %esi,%edx
f0101f3e:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101f41:	89 c7                	mov    %eax,%edi
f0101f43:	d3 ea                	shr    %cl,%edx
f0101f45:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101f49:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101f4c:	89 c2                	mov    %eax,%edx
f0101f4e:	d3 e6                	shl    %cl,%esi
f0101f50:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101f54:	d3 ea                	shr    %cl,%edx
f0101f56:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101f5a:	09 d6                	or     %edx,%esi
f0101f5c:	89 f0                	mov    %esi,%eax
f0101f5e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101f61:	d3 e7                	shl    %cl,%edi
f0101f63:	89 f2                	mov    %esi,%edx
f0101f65:	f7 75 f4             	divl   -0xc(%ebp)
f0101f68:	89 d6                	mov    %edx,%esi
f0101f6a:	f7 65 e8             	mull   -0x18(%ebp)
f0101f6d:	39 d6                	cmp    %edx,%esi
f0101f6f:	72 2b                	jb     f0101f9c <__umoddi3+0x11c>
f0101f71:	39 c7                	cmp    %eax,%edi
f0101f73:	72 23                	jb     f0101f98 <__umoddi3+0x118>
f0101f75:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101f79:	29 c7                	sub    %eax,%edi
f0101f7b:	19 d6                	sbb    %edx,%esi
f0101f7d:	89 f0                	mov    %esi,%eax
f0101f7f:	89 f2                	mov    %esi,%edx
f0101f81:	d3 ef                	shr    %cl,%edi
f0101f83:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101f87:	d3 e0                	shl    %cl,%eax
f0101f89:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101f8d:	09 f8                	or     %edi,%eax
f0101f8f:	d3 ea                	shr    %cl,%edx
f0101f91:	83 c4 20             	add    $0x20,%esp
f0101f94:	5e                   	pop    %esi
f0101f95:	5f                   	pop    %edi
f0101f96:	5d                   	pop    %ebp
f0101f97:	c3                   	ret    
f0101f98:	39 d6                	cmp    %edx,%esi
f0101f9a:	75 d9                	jne    f0101f75 <__umoddi3+0xf5>
f0101f9c:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101f9f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f0101fa2:	eb d1                	jmp    f0101f75 <__umoddi3+0xf5>
f0101fa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101fa8:	39 f2                	cmp    %esi,%edx
f0101faa:	0f 82 18 ff ff ff    	jb     f0101ec8 <__umoddi3+0x48>
f0101fb0:	e9 1d ff ff ff       	jmp    f0101ed2 <__umoddi3+0x52>
