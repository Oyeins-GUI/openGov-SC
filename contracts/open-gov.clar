
;; title: open-gov
;; version: 1.0.0
;; summary: different users can have a say on a proposal

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NO_ID_DOES_NOT_EXIST (err u400))
(define-constant ERR_VOTE_ENDED (err u401))
(define-constant ERR_VOTED_ALREADY (err u402))
(define-constant EXPIRATION u432)

(define-data-var board-admin principal tx-sender)
(define-data-var proposals-id uint u0)

(define-map Proposals { proposal-id: uint } { 
      title: (string-ascii 50),
      niche: (string-ascii 30),
      desc: (string-ascii 500),
      expiration: uint,
      status: (string-ascii 8),
      proposer: principal
   }
)
(define-map VotesInSupport { proposal-id: uint } { votes: uint })
(define-map VotesAgainst { proposal-id: uint } { votes: uint })
(define-map VotesForProposal { proposal-id: uint } { total-votes: uint })
(define-map Voters { address: principal, proposal-id: uint } { decision: (string-ascii 3) })

(define-public  (create-proposal (title (string-ascii 50)) (niche (string-ascii 30)) (desc (string-ascii 500)))
   (let 
      (
         (proposal-id (var-get proposals-id))
         (id (+ u1 proposal-id))
      )
      ;; #[filter(title, expiration, niche, desc)]
      (map-set Proposals { proposal-id: id } { 
            title: title, 
            niche: niche,
            desc: desc,
            expiration: (+ block-height EXPIRATION),
            status: "Active",
            proposer: tx-sender
      })
      (map-set VotesInSupport { proposal-id: id } { votes: u0 })
      (map-set VotesAgainst { proposal-id: id } { votes: u0 })
      (map-set VotesForProposal { proposal-id: id } { total-votes: u0 })
      (var-set proposals-id id)
      (unwrap-panic (contract-call? .events-create event-create title niche desc id tx-sender (+ block-height EXPIRATION)))
      (ok id)
   )
)

(define-public (like-proposal (proposal-id uint))
   (let
      (
         (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_NO_ID_DOES_NOT_EXIST))
         (votes (unwrap! (map-get? VotesForProposal { proposal-id: proposal-id }) ERR_NO_ID_DOES_NOT_EXIST))
         (votes-in-support (get votes (unwrap! (map-get? VotesInSupport { proposal-id: proposal-id }) ERR_NO_ID_DOES_NOT_EXIST)))
         (expiration (get expiration proposal))
         (total-votes (get total-votes votes))
         (decision "yah")
      )
      ;; #[filter(proposal-id)]
      (asserts! (< block-height expiration) ERR_VOTE_ENDED)
      (asserts! (is-none (map-get? Voters { address: tx-sender, proposal-id: proposal-id })) ERR_VOTED_ALREADY)
      (map-set Voters { address: tx-sender, proposal-id: proposal-id } { decision: decision })
      (map-set VotesForProposal { proposal-id: proposal-id } { total-votes: (+ u1 total-votes) })
      (map-set VotesInSupport { proposal-id: proposal-id } { votes: (+ u1 votes-in-support) })
      (unwrap-panic (contract-call? .events-like events-like total-votes votes-in-support proposal-id))
      (ok "liked")
   )
)

(define-public (dislike-proposal (proposal-id uint))
   (let
      (
         (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_NO_ID_DOES_NOT_EXIST))
         (votes (unwrap! (map-get? VotesForProposal { proposal-id: proposal-id }) ERR_NO_ID_DOES_NOT_EXIST))
         (votes-against (get votes (unwrap! (map-get? VotesAgainst { proposal-id: proposal-id }) ERR_NO_ID_DOES_NOT_EXIST)))
         (expiration (get expiration proposal))
         (total-votes (get total-votes votes))
         (decision "nah")
      )
      ;; #[filter(proposal-id)]
      (asserts! (< block-height expiration) ERR_VOTE_ENDED)
      (asserts! (is-none (map-get? Voters { address: tx-sender, proposal-id: proposal-id })) ERR_VOTED_ALREADY)
      (map-set Voters { address: tx-sender, proposal-id: proposal-id } { decision: decision })
      (map-set VotesForProposal { proposal-id: proposal-id } { total-votes: (+ u1 total-votes) })
      (map-set VotesAgainst { proposal-id: proposal-id } { votes: (+ u1 votes-against) })
      (unwrap-panic (contract-call? .events-dislike events-dislike total-votes votes-against proposal-id))
      (ok "disliked")
   )
)

(define-read-only (check-proposal (proposal-id uint))
   (map-get? VotesForProposal { proposal-id: proposal-id })
)

(define-read-only (get-votes-in-support (proposal-id uint))
   (map-get? VotesInSupport { proposal-id: proposal-id })
)

(define-read-only (get-votes-against (proposal-id uint))
   (map-get? VotesAgainst { proposal-id: proposal-id })
)
