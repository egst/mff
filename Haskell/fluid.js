

// a plus b

$
.let .a .be (5)
.let .b .be (6)
.let .c .be .a .plus .b

$
.let .fact .be .func .n
  (0) .if .n .is (0) .else .n .times .fact .of .n .minus (1)

$
.let .sieve .be .func .n .begin
    .let .s .be .of .list (null, null) .plus .of .list (true) .times (n - 1) ._
    .for .i .from (2) .till (n) .do
      .for .m .from (2) .to (n) .do
        .set .s .sub ($ .m .times .i) .to .false
      .end
    .end
    .return .keys .of .filter ($ .func .n .n .is (true)) .s
.end

.let .foo .be (0)  // .let .{name} .be ({js})
.let .foo .be .bar // .let .{name} .be .{name}

.let .foo .be ($ .bar .plus .baz)
.let .foo .be .of .bar .plus .baz .end

.let .foo .be (0) .let .bar .be (1)

.if (0) .then .boo .else .poo           // .if ({js}) .then .{stmt} [.else .{stmt}]
.if .foo .is .bar .then .boo .else .poo // .if .{expr}+ .then ...

.let .foo .be .of (0) .if .bar .is .baz .else (1) .end // {expr} .if .{expr}+ .else {expr}

.let .fact .be .func .n
  ._0_ .if .n .is ._0_ .else .n .times .fact .of .n .minus ._1_
