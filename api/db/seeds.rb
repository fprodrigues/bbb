participants = [
  { name: "Ana Clara", avatar_url: "/participants/1.png" },
  { name: "Bruno", avatar_url: "/participants/2.png" },
  { name: "Carla", avatar_url: "/participants/3.png" },
  { name: "Diego", avatar_url: "/participants/4.png" },
  { name: "Eduarda", avatar_url: "/participants/5.png" },
  { name: "Felipe", avatar_url: "/participants/6.png" },
  { name: "Gabriela", avatar_url: "/participants/7.png" },
  { name: "Henrique", avatar_url: "/participants/8.png" },
  { name: "Isabela", avatar_url: "/participants/9.png" },
  { name: "João", avatar_url: "/participants/10.png" },
  { name: "Larissa", avatar_url: "/participants/11.png" },
  { name: "Marcos", avatar_url: "/participants/12.png" }
]

participants.each do |data|
  participant = Participant.find_or_initialize_by(name: data[:name])

  participant.avatar_url = data[:avatar_url]
  participant.active = true
  participant.save!
end

puts "Seed concluído: #{Participant.count} participantes cadastrados."