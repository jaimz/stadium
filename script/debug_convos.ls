require! {
  person: './person.js'
  conversation: './conversation.js'
}

__names = [
  "Tatiana Toboeva",
  "Adrian O'Grady",
  "Misha Kalestki",
  "Rania Leliou",
  "Felicity Herst",
  "Warren Keyes",
  "James Ford",
  "Duncan Scott",
  "Catherine Vilhauer",
  "Ed Goward",
  "Richard Thorne",
  "Simon Hamilton",
  "Todd Roshak",
  "Eva Czekalska",
  "Gee Plumb",
  "Phillip Hounslow",
  "Ahmed Zaman",
  "Derek Lakin"
]

kNumRecents = 5
kNumFavourites = 7

class HubRepository
  ->
    @Contacts = []
    @Recents = []
    @Favourites = []
    @_convoMap = {}

    @_people = [ new person.Person(n) for n in __names ]

    with-av = new person.Person("James O'Brien")
    with-av.avatar = "./img/avatar.jpeg"

    # we push onto the start of an array with the wonderfully logical "unshift"
    @_people.unshift(with-av)

    for i from 1 to kNumRecents
      p-idx = Math.floor ((Math.random kNumRecents) * kNumRecents)
      convo = @CreateConvo(@_people[p-idx])
      @Recents.push convo

    for i in [0 til kNumFavourites]
      p-idx = Math.floor ((Math.random kNumRecents) * kNumRecents)
      convo = @CreateConvo(@_people[p-idx])
      @Favourites.push convo

    @Contacts = [ @CreateConvo(p) for p in @_people ]

  FindPerson: (id) ~>
    _.find ((c) -> c.identity is id), @Contacts

  FindConvo: (id) ~>
    @_convoMap[id] or null

  CreateConvo: (person = null) ~>
    convo = new conversation.Conversation()
    @_convoMap[convo.identity] = convo
    if person?
      convo.addParticipant(person)

    convo

  RandomContact: ~>
    l = @_people.length
    r = Math.random!
    i = Math.floor l*r

    @_people[i]


module.exports =
  Repository: HubRepository