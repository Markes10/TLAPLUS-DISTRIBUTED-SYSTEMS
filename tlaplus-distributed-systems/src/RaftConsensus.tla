--------------------------- MODULE RaftConsensus ---------------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS Server, MaxTerm

VARIABLES currentTerm, state, votedFor, votesGranted

vars == <<currentTerm, state, votedFor, votesGranted>>

Follower  == "Follower"
Candidate == "Candidate"
Leader    == "Leader"

ServerState == {Follower, Candidate, Leader}

Init ==
    /\ currentTerm = [s \in Server |-> 0]
    /\ state = [s \in Server |-> Follower]
    /\ votedFor = [s \in Server |-> "None"]
    /\ votesGranted = [s \in Server |-> {}]

Timeout(s) ==
    /\ state[s] \in {Follower, Candidate}
    /\ currentTerm[s] < MaxTerm
    /\ currentTerm' = [currentTerm EXCEPT ![s] = currentTerm[s] + 1]
    /\ state' = [state EXCEPT ![s] = Candidate]
    /\ votedFor' = [votedFor EXCEPT ![s] = s]
    /\ votesGranted' = [votesGranted EXCEPT ![s] = {s}]

RequestVote(s, j) ==
    /\ state[j] = Candidate
    /\ currentTerm[s] < currentTerm[j]
    /\ votedFor' = [votedFor EXCEPT ![s] = j]
    /\ currentTerm' = [currentTerm EXCEPT ![s] = currentTerm[j]]
    /\ state' = [state EXCEPT ![s] = Follower]
    /\ votesGranted' = [votesGranted EXCEPT ![j] = votesGranted[j] \cup {s}]

BecomeLeader(s) ==
    /\ state[s] = Candidate
    /\ Cardinality(votesGranted[s]) * 2 > Cardinality(Server)
    /\ state' = [state EXCEPT ![s] = Leader]
    /\ UNCHANGED <<currentTerm, votedFor, votesGranted>>

Next ==
    \/ \E s \in Server : Timeout(s)
    \/ \E s, j \in Server : RequestVote(s, j)
    \/ \E s \in Server : BecomeLeader(s)

(* Invariant: At most one leader exists per term *)
ElectionSafety ==
    \A s1, s2 \in Server :
        (state[s1] = Leader /\ state[s2] = Leader /\ currentTerm[s1] = currentTerm[s2]) => s1 = s2

=============================================================================
