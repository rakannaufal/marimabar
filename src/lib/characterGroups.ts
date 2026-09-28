// Display groupings for the catalog options supplied by game_attribute_definitions.
// Only options currently present in the database definition are offered for selection.
export const characterGroups: Record<string, Record<string, string[]>> = {
  hero_pool: {
    Tank: ['Akai', 'Alice', 'Atlas', 'Barats', 'Baxia', 'Belerick', 'Edith', 'Franco', 'Gatotkaca', 'Grock', 'Hylos', 'Johnson', 'Khufra', 'Lolita', 'Minotaur', 'Tigreal', 'Uranus'],
    Fighter: ['Aldous', 'Alpha', 'Alucard', 'Argus', 'Arlott', 'Badang', 'Balmond', 'Bane', 'Chou', 'Cici', 'Dyrroth', 'Freya', 'Guinevere', 'Hilda', 'Jawhead', 'Julian', 'Kaja', 'Kalea', 'Khaled', 'Lapu-Lapu', 'Leomord', 'Martis', 'Masha', 'Minsitthar', 'Paquito', 'Phoveus', 'Ruby', 'Silvanna', 'Sora', 'Sun', 'Terizla', 'Thamuz', 'X.Borg', 'Yin', 'Yu Zhong', 'Zilong'],
    Assassin: ['Aamon', 'Benedetta', 'Fanny', 'Gusion', 'Hanzo', 'Hayabusa', 'Helcurt', 'Hirara', 'Joy', 'Karina', 'Lancelot', 'Ling', 'Natalia', 'Nolan', 'Saber', 'Selena', 'Suyou', 'Yi Sun-shin'],
    Mage: ['Aurora', 'Cecilion', "Chang'e", 'Cyclops', 'Eudora', 'Faramis', 'Gord', 'Harith', 'Harley', 'Kadita', 'Kagura', 'Lylia', 'Lunox', 'Luo Yi', 'Modess', 'Nana', 'Odette', 'Parsha (Pharsa)', 'Vale', 'Valir', 'Vexana', 'Xavier', 'Yve', 'Zhask', 'Zhuxin', 'Zetian'],
    Marksman: ['Beatrix', 'Brody', 'Bruno', 'Claude', 'Clint', 'Granger', 'Hanabi', 'Irithel', 'Ixia', 'Karrie', 'Kimmy', 'Layla', 'Lesley', 'Melissa', 'Miya', 'Moskov', 'Natan', 'Obsidia', 'Popol & Kupa', 'Roger', 'Wanwan'],
    Support: ['Angela', 'Carmilla', 'Chip', 'Diggie', 'Estes', 'Floryn', 'Marcel', 'Mathilda', 'Rafaela'],
  },
  main_agent: {
    Duelist: ['Iso', 'Jett', 'Neon', 'Phoenix', 'Raze', 'Reyna', 'Waylay', 'Yoru'],
    Initiator: ['Breach', 'Fade', 'Gekko', 'KAY/O', 'Skye', 'Sova', 'Tejo'],
    Controller: ['Astra', 'Brimstone', 'Clove', 'Harbor', 'Miks', 'Omen', 'Viper'],
    Sentinel: ['Chamber', 'Cypher', 'Deadlock', 'Killjoy', 'Sage', 'Veto', 'Vyse'],
  },
  main_character: {
    'Skill Aktif': ['A124', 'Alok', 'Andrew "Fierce"', 'Chrono', 'Clu', 'Dimitri', 'Homer', 'Ignis', 'Iris', 'K', 'Kairos', 'Kenta', 'Lila', 'Orion', 'Santino', 'Skyler', 'Tatsuya', 'Wukong', 'Xayne', 'Ryden', 'Steffie'],
    'Skill Pasif · Pria': ['Alvaro', 'Antonio', 'Ford', 'Hayato', 'Jai', 'Joseph', 'Jota', 'J.Biebs', 'Kla', 'Luqueta', 'Maro', 'Maxim', 'Miguel', 'Nairi', 'Rafael', 'Shirou', 'Thiva', 'Wolfrahh'],
    'Skill Pasif · Wanita': ['A-Patroa', 'Caroline', 'Dasha', 'Suzy', 'Kapella', 'Kelly', 'Laura', 'Luna', 'Misha', 'Moco', 'Nikita', 'Notora', 'Olivia', 'Paloma', 'Sonia', 'Sonia Awakened', 'Shani'],
  },
}

export function groupedCharacterOptions(key: string, options: string[]): { label: string; options: string[] }[] {
  const groups = characterGroups[key]
  if (!groups) return []
  const allowed = new Set(options)
  const result = Object.entries(groups).map(([label, names]) => ({ label, options: names.filter(name => allowed.has(name)) })).filter(group => group.options.length)
  const listed = new Set(result.flatMap(group => group.options))
  const other = options.filter(name => !listed.has(name))
  if (other.length) result.push({ label: 'Lainnya', options: other })
  return result
}
