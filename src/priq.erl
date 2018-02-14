-module(priq).

%% An implemention of a priority queue, backed by a persistent* skew binary heap.
%%
%% A skew binary heap 
%%
%% Persistence in this case means expressed as a term of purely functional data structures.
%%
%% Credits to Chris Okasaki for a phenomenal book.

-export([new/0, insert/2, find_min/1, delete_min/1, merge/2]).

-record(tree, {rank=0, root, elem_rest=[], rest=[]}).
-record(sbheap, {trees=[]}).
-record(bsheap, {root, hheap=#sbheap{}}).

%% Public Interface

new() -> bs_new().

merge(H1, H2) -> bs_merge(H1,H2).

insert(E, H) -> bs_insert(E, H).

find_min(H) -> bs_lookup_min(H).

delete_min(H) -> bs_delete_min(H).

%% Bootstrapped Heap Interface

bs_new() -> empty.

bs_merge(empty, H=#bsheap{}) -> H;
bs_merge(H=#bsheap{},empty) -> H;
bs_merge(H1=#bsheap{root=X,hheap=SBHeap},H2=#bsheap{root=Y}) when X =< Y ->
  H1#bsheap{hheap=sb_insert(H2,SBHeap)};
bs_merge(H1=#bsheap{},H2=#bsheap{}) ->
  bs_merge(H2,H1).

bs_insert(E, H) -> bs_merge(#bsheap{root=E},H).

bs_lookup_min(empty) -> error;
bs_lookup_min(#bsheap{root=X}) -> {ok,X}.

bs_delete_min(empty) -> error;
bs_delete_min(#bsheap{hheap=#sbheap{trees=[]}}) -> {ok,empty};
bs_delete_min(#bsheap{hheap=SBHeap}) ->
  {ok,#bsheap{root=Root,hheap=SB1}}=sb_lookup_min(SBHeap),
  {ok,SB2}=sb_delete_min(SBHeap),
  {ok,#bsheap{root=Root,hheap=sb_merge(SB1,SB2)}}.

%% Skew Binomial Heap Interface

sb_insert(E, #sbheap{trees=[T1,T2|TRest]}) when T1#tree.rank =:= T2#tree.rank ->
  N=skew_link(E, T1, T2),
  #sbheap{trees=[N|TRest]};
sb_insert(E, #sbheap{trees=Trees}) ->
  N=#tree{root=E},
  #sbheap{trees=[N|Trees]}.

sb_lookup_min(#sbheap{trees=Trees}) -> do_lookup_min(Trees).

sb_merge(#sbheap{trees=T1s}, #sbheap{trees=T2s}) ->
  #sbheap{trees=merge_trees(normalize(T1s),normalize(T2s))}.

merge_trees([], Ts) -> Ts;
merge_trees(Ts, []) -> Ts;
merge_trees([T1|T1s], [T2|T2s]) when T1#tree.rank =:= T2#tree.rank ->
  ins_tree(sbt_link(T1,T2),merge_trees(T1s, T2s));
merge_trees([T1|T1s], [T2|T2s]) when T1#tree.rank < T2#tree.rank ->
  [T1|merge_trees(T1s, [T2|T2s])];
merge_trees([T1|T1s], [T2|T2s]) ->
  [T2|merge_trees([T1|T1s], T2s)].

normalize(Ts) -> lists:foldl(fun ins_tree/2, [], Ts).

sb_delete_min(#sbheap{trees=[]}) -> error;
sb_delete_min(#sbheap{trees=Trees}) ->
  {#tree{elem_rest=Xs,rest=C},Ts}=tree_get_min(Trees),
  M=#sbheap{trees=merge_trees(lists:reverse(C),normalize(Ts))},
  {ok,lists:foldl(fun sb_insert/2, M, Xs)}.

%% Skew Binomial Tree Functions

sbt_link(X=#tree{root=XRoot}, Y=#tree{root=YRoot}) when XRoot =< YRoot ->
      X#tree{rank=X#tree.rank+1,rest=[Y|X#tree.rest]};
sbt_link(X=#tree{}, Y=#tree{}) ->
      Y#tree{rank=X#tree.rank+1,rest=[X|Y#tree.rest]}.

skew_link(E, X, Y) ->
  N=#tree{root=NRoot,elem_rest=NRest}=sbt_link(X, Y),
  if
    E =< NRoot ->
      N#tree{root=E,elem_rest=[NRoot|NRest]};
    true ->
      N#tree{elem_rest=[E|NRest]}
  end.

tree_get_min([X]) -> {X, []};
tree_get_min([X|Xs]) ->
  {Y, Ys} = tree_get_min(Xs),
  if
    X#tree.root =< Y#tree.root ->
      {X,Xs};
    true ->
      {Y,[X|Ys]}
  end.

do_lookup_min([]) -> error;
do_lookup_min([#tree{root=Root}]) -> {ok,Root};
do_lookup_min([#tree{root=Root}|Rest]) ->
  {ok,lists:foldl(fun(#tree{root=R},Acc) -> min(R,Acc) end, Root, Rest)}.

ins_tree(T, []) -> [T];
ins_tree(T1, [T2|Ts]) when T1#tree.rank < T2#tree.rank -> [T1,T2|Ts];
ins_tree(T1, [T2|Ts]) -> ins_tree(sbt_link(T1,T2), Ts).
