; RUN: llc < %s -march=x86-64 -o - | FileCheck %s

; Reuse the flags value from the add instructions instead of emitting separate
; testl instructions.

; Use the flags on the add.

; CHECK: add_zf:
;      CHECK: addl    (%rdi), %esi
; CHECK-NEXT: movl    %edx, %eax
; CHECK-NEXT: cmovnsl %ecx, %eax
; CHECK-NEXT: ret

define i32 @add_zf(i32* %x, i32 %y, i32 %a, i32 %b) nounwind {
	%tmp2 = load i32* %x, align 4		; <i32> [#uses=1]
	%tmp4 = add i32 %tmp2, %y		; <i32> [#uses=1]
	%tmp5 = icmp slt i32 %tmp4, 0		; <i1> [#uses=1]
	%tmp.0 = select i1 %tmp5, i32 %a, i32 %b		; <i32> [#uses=1]
	ret i32 %tmp.0
}

declare void @foo(i32)

; Don't use the flags result of the and here, since the and has no
; other use. A simple test is better.

; CHECK: bar:
; CHECK: testb   $16, %dil

define void @bar(i32 %x) nounwind {
  %y = and i32 %x, 16
  %t = icmp eq i32 %y, 0
  br i1 %t, label %true, label %false
true:
  call void @foo(i32 %x)
  ret void
false:
  ret void
}

; Do use the flags result of the and here, since the and has another use.

; CHECK: qux:
;      CHECK: andl    $16, %edi
; CHECK-NEXT: jne

define void @qux(i32 %x) nounwind {
  %y = and i32 %x, 16
  %t = icmp eq i32 %y, 0
  br i1 %t, label %true, label %false
true:
  call void @foo(i32 %y)
  ret void
false:
  ret void
}
