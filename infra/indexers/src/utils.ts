// Fonction pour décoder une chaîne hexadécimale en une chaîne de caractères
export function hexToAscii(hex: string): string {
  // Supprimer le préfixe "0x" s'il est présent
  if (hex.startsWith('0x')) {
    hex = hex.slice(2);
  }

  // Supprimer les zéros non significatifs au début de la chaîne
  hex = hex.replace(/^0+/, '');

  // Convertir la chaîne hexadécimale en tableau de bytes
  const bytes = hex.match(/.{1,2}/g)?.map(byte => parseInt(byte, 16));

  // Convertir le tableau de bytes en une chaîne de caractères ASCII
  if (bytes) {
    return String.fromCharCode(...bytes);
  } else {
    return '';
  }
}
