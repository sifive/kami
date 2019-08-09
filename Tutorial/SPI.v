Require Import Coq.Lists.List. Import ListNotations.
  
Axiom kleene : forall {T}, (list T -> Prop) -> list T -> Prop.
Axiom plus : forall {T}, (list T -> Prop) -> list T -> Prop.
Axiom app : forall {T}, (list T -> Prop) -> (list T -> Prop) -> list T -> Prop.
Lemma app_empty_r {T} (P Q : list T -> Prop) t : P t -> Q nil -> app P Q t. Admitted.
Axiom either : forall {T}, (list T -> Prop) -> (list T -> Prop) -> list T -> Prop.
Axiom maybe : forall {T}, (list T -> Prop) -> list T -> Prop.
Local Notation "x ^*" := (kleene x) (at level 50).
Local Notation "x ^+" := (plus x) (at level 50).
Local Infix "+++" := app (at level 60).

Module List. Section __.
  Context {T : Type}.
  Definition interleave_body interleave (zs xs ys : list T) : Prop :=
    match zs with
    | nil => xs = nil /\ zs = nil
    | cons z zs' =>
        (exists xs', xs = cons z xs' /\ interleave zs' xs' ys ) \/
        (exists ys', ys = cons z ys' /\ interleave zs' xs  ys')
    end.
  Definition interleave (xs ys zs : list T) : Prop :=
    (fix interleave zs := interleave_body interleave zs) zs xs ys.

  Lemma interleave_rcons z zs xs ys y (H : z = y) (HH : interleave xs ys zs) : interleave xs (y::ys) (z::zs).
  Proof. subst; cbn; eauto. Qed.
  Lemma interleave_lcons z zs xs ys x (H : z = x) (HH : interleave xs ys zs) : interleave (x::xs) ys (z::zs).
  Proof. subst; cbn; eauto. Qed.

  Lemma interleave_rapp z zs xs ys y (H : z = y) (HH : interleave xs ys zs) : interleave xs (y++ys) (z++zs).
  Proof. subst; induction y; cbn; eauto. Qed.
  Lemma interleave_lapp z zs xs ys x (H : z = x) (HH : interleave xs ys zs) : interleave (x++xs) ys (z++zs).
  Proof. subst; induction x; cbn; eauto. Qed.

  Lemma interleave_nil_r zs : interleave zs nil zs.
  Proof. induction zs; cbn; eauto. Qed.
  Lemma interleave_nil_l zs : interleave zs nil zs.
  Proof. induction zs; cbn; eauto. Qed.
End __. End List.


Module TracePredicate.
  Definition flat_map {A B} (P:A->list B->Prop) xs :=
    List.fold_right app (eq nil) (List.map P xs).

  (* [interleave] trace of *arbitrarily small slices of* [P] and [Q].
     This sometimes makes sense for completely independent streams of
     events, but consider [(P \/ Q)^*] instead first. *)
  Definition interleave {T} (P Q : list T -> Prop) :=
    fun zs => exists xs ys, List.interleave xs ys zs /\ P xs /\ Q ys.

  Lemma interleave_rapp {T} {P QQ Q : list T -> Prop} z zs
    (H : Q z) (HH : interleave P QQ zs) : interleave P (QQ +++ Q) (z++zs).
  Proof.
    destruct HH as (?&?&?&?&?).
    eexists _, _; split.
    eapply List.interleave_rapp; eauto.
    split; eauto.
  Admitted.
  
  Lemma interleave_lapp {T} {PP P Q : list T -> Prop} z zs
    (H : P z) (HH : interleave PP Q zs) : interleave (PP +++ P) Q (z++zs).
  Proof.
    destruct HH as (?&?&?&?&?).
    eexists _, _; split.
    eapply List.interleave_lapp; eauto.
    split; eauto.
  Admitted.

  Definition interleave_rcons {T} {P QQ Q} (z:T) zs H HH : interleave _ _ (cons _ _) :=
    @interleave_rapp T P QQ Q [z] zs H HH.
  Definition interleave_lcons {T} {PP P Q} (z:T) zs H HH : interleave _ _ (cons _ _):=
    @interleave_lapp T PP P Q [z] zs H HH.

  Lemma interleave_rkleene {T} {P Q : list T -> Prop} z zs
    (H : Q^* z) (HH : interleave P (Q^* ) zs) : interleave P (Q^* ) (z++zs).
  Proof.
    destruct HH as (?&?&?&?&?).
    eexists _, _; split.
    eapply List.interleave_rapp; eauto.
    split; eauto.
  Admitted.
  
  Lemma interleave_lkleene {T} {P Q : list T -> Prop} z zs
    (H : P^* z) (HH : interleave (P^* ) Q zs) : interleave (P^* ) Q (z++zs).
  Proof.
    destruct HH as (?&?&?&?&?).
    eexists _, _; split.
    eapply List.interleave_lapp; eauto.
    split; eauto.
  Admitted.

  Definition interleave_rkleene_cons {T} {P Q} (z:T) zs H HH : interleave _ _ (cons _ _) :=
    @interleave_rkleene T P Q [z] zs H HH.
  Definition interleave_lkleene_cons {T} {P Q} (z:T) zs H HH : interleave _ _ (cons _ _):=
    @interleave_lkleene T P Q [z] zs H HH.

  Lemma interleave_kleene_l_app_r {T} (A B C : list T -> Prop) (bs cs : list T)
    (HB : TracePredicate.interleave (kleene A) B bs)
    (HC : TracePredicate.interleave (kleene A) C cs)
    : TracePredicate.interleave (kleene A) (B +++ C) (cs ++ bs).
  Admitted.
  (* TODO: how do I actually prove this in a loop *)
End TracePredicate.

Require Import Kami.All.

Definition bits {w} : word w -> list bool. Admitted.
Lemma length_bits w x : List.length (@bits w x) = w. Admitted.
Lemma bits_nil x : @bits 0 x = nil.
Proof.
  pose proof length_bits x as H.
  destruct (bits x); [trivial | inversion H].
Qed.
Definition x : nat. exact O. Qed.

Section Named.
  Context (name : string).
  Local Open Scope kami_action.
  Local Open Scope kami_expr.
  Local Notation "@^ x" := (name ++ "_" ++ x)%string (at level 0).

  Definition SPI := MODULE {
         Register @^"hack_for_sequential_semantics" : Bit 0 <- Default
    with Register @^"i"           : Bit 4 <- Default
    with Register @^"sck"         : Bool  <- Default
    with Register @^"tx_fifo"     : Bit 8 <- Default
    with Register @^"rx_fifo"     : Bit 8 <- Default
    with Register @^"rx_valid"    : Bool  <- Default
    
    with Rule @^"cycle" := (
      Write @^"hack_for_sequential_semantics" : Bit 0 <- $$(WO);
      Read sck <- @^"sck";
      Read i : Bit 4 <- @^"i";
      Read tx_fifo : Bit 8 <- @^"tx_fifo";
      If (*!*) #i == $$@natToWord 4 0 then Retv else (
        If (#sck) then (
          Write @^"sck" : Bool <- $$false;
          Call "PutSCK"($$false : Bool);
          Call "PutMOSI"((UniBit (TruncMsb 7 1) #tx_fifo) : Bit 1);
          Retv
        ) else (
          Read rx_fifo : Bit 8 <- @^"rx_fifo";
          Call miso : Bit 1 <- "GetMISO"();
          Write @^"rx_fifo" : Bit 8 <- BinBit (Concat 7 1) (UniBit (TruncMsb 1 7) #rx_fifo) #miso;
          Write @^"sck" : Bool <- $$true;
          Call "PutSCK"($$true : Bool);
          Call "PutMOSI"((UniBit (TruncMsb 7 1) #tx_fifo) : Bit 1);
          Write @^"tx_fifo" : Bit 8 <- BinBit (Concat 7 1) (UniBit (TruncMsb 1 7) #tx_fifo) $$(@ConstBit 1 $x);
          Retv
        );
      Retv);

    Retv)
    
    with Method "write" (data : Bit 8) : Bool := (
      Write @^"hack_for_sequential_semantics" : Bit 0 <- $$(WO);
      Read i <- @^"i";
      If (#i == $$@natToWord 4 0) then (
        Write @^"tx_fifo" : Bit 8 <- #data;
        Write @^"i" <- $$@natToWord 4 8;
        Write @^"rx_valid" <- $$false;
        Ret $$false
      ) else (
        Ret $$true
      ) as b;
      Ret #b
    )
    
    with Method "read" () : Bool := ( (* TODO return pair *)
      Write @^"hack_for_sequential_semantics" : Bit 0 <- $$(WO);
      Read rx_valid <- @^"rx_valid";
      If (#rx_valid) then (
        Read data : Bit 8 <- @^"rx_fifo";
        Write @^"rx_valid" <- $$false;
        Ret $$false (* TODO: return (data, false) *)
      ) else (
        Ret $$true
      ) as r;
      Ret #r
    )
  }.

  Definition cmd_write arg err t := exists r : RegsT, t =
    [[(r, (Meth ("write", existT SignT (Bit 8, Bool) (arg, err)), @nil MethT))]].
  Definition cmd_read (ret : word 8) err t := exists r : RegsT, t =
    [[(r, (Meth ("read", existT SignT (Void, Bool) (wzero 0, err)), @nil MethT))]].
  Definition iocycle miso sck mosi t := exists r : RegsT, t = [[(r, (Rle (name ++ "_cycle"),
      [("GetMISO", existT SignT (Void, Bit 1) (wzero 0, WS miso WO));
      ("PutSCK",   existT SignT (Bool, Void)  (sck, wzero 0));
      ("PutMOSI",  existT SignT (Bit 1, Void) (WS mosi WO, wzero 0))]))]].

  Definition nop x := (exists arg, cmd_write arg true x) \/ (exists ret, cmd_read ret true x).
  
  Inductive p :=
  | getmiso (_ : forall miso : bool, p)
  | putsck (_ : bool) (_ : p)
  | putmosi (_ : bool) (_ : p)

  | yield (_ : p)
  | ret (_ : word 8).

  Fixpoint xchg_prog (n : nat) : forall (tx : word 8) (rx : word 8), p :=
    match n with
    | O => fun _ rx => ret rx
    | S n => fun tx rx =>
      let mosi := wmsb tx false in
      let tx := WS false (split1 7 1 tx) in
      putsck false (
      putmosi mosi (
      yield (
      getmiso (fun miso =>
      let rx := WS miso (split1 7 1 rx) in
      putsck true (
      putmosi mosi (
      yield (
      @xchg_prog n tx rx
      )))))))
    end.

  Fixpoint interp (e : p) : list MethT -> word 8 -> list (list FullLabel) -> Prop :=
    match e with
    | getmiso k => fun l w t => exists miso, interp (k miso) (l++[("GetMISO", existT SignT (Void, Bit 1) (wzero 0, WS miso WO))]) w t
    | putsck sck k => fun l w t => interp k (l++[("PutSCK", existT SignT (Bool, Void) (sck, wzero 0))]) w t
    | putmosi mosi k => fun l w t => interp k (l++[("PutMOSI", existT SignT (Bit 1, Void) (WS mosi WO, wzero 0))]) w t
    | yield k => fun l w t => exists r, (eq [[(r, (Rle (name ++ "_cycle"), l))]] +++ interp k nil w) t
    | ret w => fun l' w' t => w' = w /\ t = nil
    end.

  Definition silent t := exists miso mosi, iocycle miso false mosi t.

  Definition spec := TracePredicate.interleave (kleene nop) (kleene (fun t =>
    silent t \/
    exists tx rx, (cmd_write tx false +++
                   interp (xchg_prog 8 tx (wzero 8)) nil rx +++
                   maybe (cmd_read rx false)) t)).

  Definition enforce_regs (regs:RegsT) tx_fifo i rx_fifo rx_fifo_len sck := regs =
    [(@^"hack_for_sequential_semantics", existT _ (SyntaxKind (Bit 0)) WO);
     (@^"tx_fifo", existT _ (SyntaxKind (Bit 8)) tx_fifo);
     (@^"i", existT _ (SyntaxKind (Bit 4)) i);
     (@^"rx_fifo", existT _ (SyntaxKind (Bit 8)) rx_fifo);
     (@^"rx_fifo_len", existT _ (SyntaxKind (Bit 4)) rx_fifo_len);
     (@^"sck", existT _ (SyntaxKind Bool) sck) ].

  Ltac expand := (* Goal: invariant *)
    ((esplit; trivial); [..|solve[cbv [enforce_regs] in *;
        repeat match goal with
        | _ => progress discharge_string_dec
        | _ => progress cbn [fst snd]
        | |- context G [match ?x with _ => _ end] =>
           let X := eval hnf in x in
           progress change x with X
        | _ => progress (f_equal; [])
        | |- ?l = ?r =>
            let l := eval hnf in l in
            let r := eval hnf in r in
            progress change (l = r)
        | _ => exact eq_refl
               end]]; subst).

  (* draining case only *)
  Goal forall s past,
    Trace SPI s past ->
    exists tx tx_len rx rx_len sck,
    enforce_regs s tx tx_len rx rx_len sck /\
    wordToNat tx_len <> 0 /\
    (forall frx future, TracePredicate.interleave (kleene nop) (interp (xchg_prog (wordToNat tx_len) tx rx) nil frx +++ kleene spec ) future ->
    TracePredicate.interleave (kleene nop) (interp (xchg_prog 8 tx rx) nil frx) (future ++ past)).
  Proof.
    intros s past.
    pose proof eq_refl s as MARKER.
    induction 1 as [A B C D | regsBefore t regUpds regsAfter E _ IHTrace HStep K I].
    { subst. admit. }

    unshelve epose proof InvertStep (@Build_BaseModuleWf SPI _) _ _ _ HStep as HHS;
      clear HStep; [abstract discharge_wf|..|rename HHS into HStep].
    1,2,3: admit.

    repeat match goal with
      | _ => progress intros
      | _ => progress clean_hyp_step
      | _ => progress discharge_string_dec
      | _ => progress cbn [SPI getMethods baseModule makeModule makeModule' type evalExpr isEq evalConstT Kind_rect List.app map fst snd projT1 projT2 invariant doUpdRegs findReg] in *
      | _ => progress cbv [invariant] in *
      | K: UpdRegs _ _ ?z |- _ =>
          let H := fresh K in
          unshelve epose proof (NoDup_UpdRegs _ _ K); clear K; [> ..| progress subst z]
      | |- NoDup _ => admit
      | |- context G [@cons ?T ?a ?b] =>
          assert_fails (idtac; match b with nil => idtac end);
          let goal := context G [@List.app T (@cons T a nil) b] in
          change goal
      | _ => progress rewrite ?app_assoc, ?app_nil_r
      | H : ?T -> _ |- _ => assert_succeeds (idtac; match type of T with Prop => idtac end); specialize (H ltac:(auto))
    end.

    {
      repeat match goal with
      | _ => eapply ex_intro || eapply conj
      | _ => eapply IHTrace; clear IHTrace
      end.

      1: solve[cbv [enforce_regs doUpdRegs] in *;subst;clear;
      repeat match goal with
      | _ => progress discharge_string_dec
      | _ => progress cbn [fst snd]
      | |- context G [match ?x with _ => _ end] =>
         let X := eval hnf in x in
         progress change x with X
      | _ => progress (f_equal; [])
      | |- ?l = ?r =>
          let l := eval hnf in l in
          let r := eval hnf in r in
          progress change (l = r)
      | _ => exact eq_refl
      end].

      1:solve[auto].
      
      intros.
      progress rewrite ?app_assoc, ?app_nil_r.
      eapply H10.

      remember (wordToNat tx_len) as i; destruct i; repeat rewrite <-Heqi in *; try solve [congruence].
      Notation "( x , y , .. , z )" := (existT _ .. (existT _ x y) .. z) : core_scope.
      cbn [xchg_prog].
      cbn [interp].
      eapply TracePredicate.interleave_kleene_l_app_r.


    (* 
    destruct IHTrace as [sck tx tx_fifo i rx_fifo rx_fifo_len IH TODO1 Henforce]; cbv [enforce_regs] in *;
      repeat match goal with
        | _ => progress intros
        | _ => progress clean_hyp_step
        | _ => progress discharge_string_dec
        | _ => progress cbn [SPI getMethods baseModule makeModule makeModule' type evalExpr isEq evalConstT Kind_rect List.app map fst snd projT1 projT2 invariant doUpdRegs findReg] in *
        | _ => progress cbv [invariant] in *
        | K: UpdRegs _ _ _ |- _ => unshelve ( repeat erewrite (NoDup_UpdRegs _ _ K) in * ); clear K
        | |- NoDup _ => admit
      end.

    { (*1*)
      expand.
      replace rv1 with (wzero 4) in * by admit.
      change (wordToNat (wzero 4)) with 0; cbn [skipn].
  
        { 
          cbv [spec].
          simple refine (TracePredicate.interleave_rkleene_cons _ _ _ _).
          2:eassumption.
          match goal with |- ?f ?x => enough (sck false x) by admit end.
          cbv [sck iocycle].
          eexists _, _, _.
          repeat f_equal; eauto.
          1,2: admit. (* bbv... *)
        }
  
        idtac.
        all : cbn [map fst].
        1,2: admit. (* NoDup *)
      }
    
      4: {
        match goal with
        | H: UpdRegs _ _ _ |- _ => apply NoDup_UpdRegs in H; [symmetry in H; destruct H|..]
        end.
        right. econstructor; try trivial.
  
        2: cbv [enforce_regs] in *;
        repeat match goal with
        | _ => progress discharge_string_dec
        | _ => progress cbn [fst snd]
        | |- context G [match ?x with _ => _ end] =>
           let X := eval hnf in x in
           progress change x with X
        | _ => progress (f_equal; [])
        | |- ?l = ?r =>
            let l := eval hnf in l in
            let r := eval hnf in r in
            progress change (l = r)
        | _ => exact eq_refl
        end; fail.
  
        {
          cbv [spec].
          eapply TracePredicate.interleave_rcons; try eassumption; [].
          unshelve erewrite (_ : skipn (wordToNat $8) (bits arg) = nil). admit.
          cbn [mosis TracePredicate.flat_map fold_right map].
          eapply app_empty_r; eauto.
          cbv [cmd_write]. eexists.
          repeat f_equal. }
  
        1,2 : match goal with |- NoDup _ => admit end.
        }
  
      10: {
        match goal with
        | H: UpdRegs _ _ _ |- _ => apply NoDup_UpdRegs in H; [symmetry in H; destruct H|..]
        end.
        left. econstructor.
  
        2: cbv [enforce_regs] in *;
        repeat match goal with
        | _ => progress discharge_string_dec
        | _ => progress cbn [fst snd]
        | |- context G [match ?x with _ => _ end] =>
           let X := eval hnf in x in
           progress change x with X
        | _ => progress (f_equal; [])
        | |- ?l = ?r =>
            let l := eval hnf in l in
            let r := eval hnf in r in
            progress change (l = r)
        | _ => exact eq_refl
        end; fail.
  
        { simple refine (TracePredicate.interleave_lkleene_cons _ _ _ _); eauto.
          lazymatch goal with |- kleene ?p ?x => enough (p x) by admit end.
          right. eexists _. eexists _.
          repeat f_equal; eauto using f_equal2. }
  
        1,2: admit. }
      all : admit. }

    { destruct IHTrace.
      cbv [enforce_regs] in *.
  
      unshelve (idtac;
      let pf := open_constr:(InvertStep (@Build_BaseModuleWf SPI _) _ _ _ HStep) in
      destruct pf);
      [abstract discharge_wf|..];
      repeat match goal with
        | H: Trace _ _ |- _ => clear H
        | _ => progress intros
        | _ => progress clean_hyp_step
        | _ => progress cbn [SPI getMethods baseModule makeModule makeModule' type evalExpr isEq evalConstT Kind_rect List.app map fst snd projT1 projT2] in *
        | H: UpdRegs _ _ _ |- _ => apply NoDup_UpdRegs in H; symmetry in H; destruct H
      end.

  1,2,3,4,5,6,7,8,9,10:shelve.
  all : let T := type of HUpdRegs in idtac T.
  all : clear HStep; clear H.

  4: {
    match goal with
    | H: UpdRegs _ _ _ |- _ => apply NoDup_UpdRegs in H; [symmetry in H; destruct H|..]
    end.
    right. esplit; trivial.

    2: cbv [enforce_regs] in *;
      repeat match goal with
      | _ => progress discharge_string_dec
      | _ => progress cbn [fst snd]
      | |- context G [match ?x with _ => _ end] =>
         let X := eval hnf in x in
         progress change x with X
      | _ => progress (f_equal; [])
      | |- ?l = ?r =>
          let l := eval hnf in l in
          let r := eval hnf in r in
          progress change (l = r)
      | _ => exact eq_refl
      end.

    eapply TracePredicate.interleave_rcons; eauto.

    { eapply app_empty_r; cycle 1.
      { split; trivial.
        replace (skipn (wordToNat $8) (bits arg)) with (@nil bool); cycle 1. {
          clear.
          pose proof length_bits arg as HA.
          pose proof firstn_skipn (@wordToNat 4 $8) (bits arg) as HB.
          pose proof firstn_all (bits arg) as HC.
          rewrite HA in HC.
          setoid_rewrite HC in HB.
          eapply (f_equal (@List.length _)) in HB.
          rewrite app_length in HB.
          destruct (skipn (wordToNat $8) (bits arg)); trivial; cbn in *; Lia.lia.
        }
        cbv [mosis].
        cbn [TracePredicate.flat_map map fold_right].
        exact eq_refl. }
      { cbv [cmd_write]. eexists.
        repeat f_equal. } }
    cbv [spec exchange].
    admit. (* finalize cycle *)

    1,2: admit. (* NoDup *) }

  
    
    


    
    
    eapply andb_prop in H4; destruct H4.
    rewrite andb_true_l in H.
   *)

Abort.

End Named.

  (* Notation "( x , y , .. , z )" := (existT _ .. (existT _ x y) .. z) : core_scope. *)