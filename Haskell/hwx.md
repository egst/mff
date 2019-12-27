Maximilian Kulikov

---

## Definitions

For a group $(G, *)$: $aG := a * G := (\{a * g \mid \forall g \in G\}, *)$

I will use $aG$ for multiplication and $a + G$ for addition specifically.

$\Bbb{Z}_n := (\{0, \cdots, n - 1\}, +_n)$, where $a +_n b :\equiv a + b \mod n$

For $(G, *)$ and its normal subgroup $(H, *)$:

$G/H := (\{gH \mid \forall g \in G\}, \hat{*})$, where $aH\ \hat{*}\ bH := (a * b) H$

For groups $(G, *)$ and $(H, \circ)$:

$G \cong H$ $\iff$ $\exists$ bijective $f: G \to H$ such that $\forall u, v \in G:$ $f(u * v) = f(u) \circ f(v)$

## The assignment

Prove that for $(\Bbb{Z}, +)$: $n\Bbb{Z}/m\Bbb{Z} \cong \Bbb{Z}_{m/n}$ where $n \mid m$

## Proof

$\Bbb{Z}_{m/n} = (M, +_{m/n})$ where $M = \{0, \cdots, m/n - 1\}$

$n\Bbb{Z}/m\Bbb{Z} = (Q, \hat{+})$

where $Q = \{i + m\Bbb{Z} \mid \forall i \in n\Bbb{Z}\} = \{in + m\Bbb{Z} \mid \forall i \in \Z\}$

and $(in + m\Bbb{Z})\ \hat{+}\ (jn + m\Bbb{Z}) = n(i + j) + \Bbb{Z}$

Let $f: M \to Q$ be defined as: $f(a) := na + m\Bbb{Z}$

With such definition, the following holds:

$f(a +_{m/n} b) = n(a +_{m/n} b) + m\Bbb{Z} \overset{*}{=} n(a + b) + m\Bbb{Z} = (na + m\Bbb{Z})\ \hat{+}\ (nb + m\Bbb{Z}) = f(a)\ \hat{+}\ f(b)$

So $f$ is a homomorfism.

Explanation of $\overset{*}{=}:$

For $k \equiv l \mod m/n$:

$\forall i \in \Bbb{Z}$ $\exists j \in \Bbb{Z}:$ $nk + mi = nl + mj$ $\implies$ $nk + m\Bbb{Z} \subseteq nl + m\Bbb{Z}$

$\forall j \in \Bbb{Z}$ $\exists i \in \Bbb{Z}:$ $nl + mj = nk + mi$ $\implies$ $nl + m\Bbb{Z} \subseteq nk + m\Bbb{Z}$

since $\exists p \in \Bbb{Z}:$ $k = l + \frac{m}{n}p$ $\implies$ $nk + mi = nl + n\frac{m}{n}p + mi = nl + mp + mi = nl + m(p + i)$ and vice versa.

Therefore $nk + m\Bbb{Z} = nl + m\Bbb{Z}$ for $k \equiv l \mod m/n$.

Now, since $a +_{m/n} b \equiv a + b \mod m/n$, the $\overset{*}{=}$ equality holds.

It remains to show, that $f$ is bijective.

Trivial: $\forall m \in M$ $\exists! q \in Q:$ $f(m) = q$

Nonexistance of two distinct $a \ne b \in M$ such that $f(a) = f(b)$ is trivial as well.

Existance of at least one $a \in M$ $\forall q \in M$ such that $f(a) = q$:

$q = nx + m\Bbb{Z} = na + m\Bbb{Z}$ for $x \equiv a \mod m/n$ where $a \in \{0, \cdots, m/n - 1\} = M$

Therefore $\forall q \in Q$ $\exists! m \in M:$ $f(m) = q$ and $f$ is bijective.

$f$ is isomorphism $\implies$ $n\Bbb{Z}/m\Bbb{Z} \cong \Bbb{Z}_{m/n}$ $\blacksquare$







