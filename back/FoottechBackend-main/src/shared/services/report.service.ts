import PDFDocument from 'pdfkit';
import { mkdirSync, createWriteStream } from 'fs';
import path from 'path';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

export interface MatchReportData {
  id: number;
  adversaire: string;
  dateHeure: Date;
  lieu: string | null;
  isHome: boolean;
  formation: string | null;
  homeScore: number;
  awayScore: number;
  matchStatus: string;
  lineup: Array<{
    firstName: string;
    lastName: string;
    numeroMaillot: number | null;
    status: string;
  }>;
  events: Array<{
    eventType: string;
    minute: number;
    playerName: string | null;
    comment: string | null;
  }>;
  stats: Array<{
    playerName: string;
    minutesPlayed: number;
    goals: number;
    assists: number;
    goalsConceded: number;
    yellowCards: number;
    redCards: number;
  }>;
  evaluations: Array<{
    playerName: string;
    note: number | null;
    commentaire: string | null;
  }>;
}

const REPORT_DIR = path.join(env.UPLOAD_DIR, 'reports');

const statusLabels: Record<string, string> = {
  SCHEDULED: 'Programmé',
  LIVE: 'En cours',
  FINISHED: 'Terminé',
  CANCELLED: 'Annulé',
  POSTPONED: 'Reporté',
};

const eventLabels: Record<string, string> = {
  GOAL: 'But',
  ASSIST: 'Passe décisive',
  YELLOW_CARD: 'Carton jaune',
  RED_CARD: 'Carton rouge',
  SUBSTITUTION_IN: 'Entrée en jeu',
  SUBSTITUTION_OUT: 'Sortie',
  INJURY: 'Blessure',
};

/**
 * Generates a match report PDF on disk and returns its public URL.
 */
export async function generateMatchReportPdf(data: MatchReportData): Promise<string> {
  mkdirSync(REPORT_DIR, { recursive: true });
  const safeOpponent = data.adversaire.replace(/[^a-zA-Z0-9-_]+/g, '_').slice(0, 40) || 'Match';
  const fileName = `match-${data.id}-${safeOpponent}.pdf`;
  const filePath = path.join(REPORT_DIR, fileName);
  const absolutePath = path.isAbsolute(filePath) ? filePath : path.resolve(filePath);

  const doc = new PDFDocument({ margin: 50, size: 'A4' });
  const stream = createWriteStream(absolutePath);
  doc.pipe(stream);

  await draw(doc, data);
  doc.end();

  await new Promise<void>((resolve, reject) => {
    stream.on('finish', resolve);
    stream.on('error', reject);
  });

  logger.info('Match report PDF generated', { fileName });
  return `/uploads/reports/${encodeURIComponent(fileName)}`;
}

async function draw(
  doc: PDFKit.PDFDocument,
  data: MatchReportData
): Promise<void> {
  // Header
  doc.fontSize(18).fillColor('#0B5D3B').text('FootTech — Rapport de match', { align: 'center' });
  doc.moveDown(0.5);

  const dateLabel = data.dateHeure.toLocaleDateString('fr-FR', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });

  doc.fontSize(13).fillColor('#0F172A');
  doc.text(`Adversaire : ${data.adversaire}`);
  doc.text(`Date : ${dateLabel}`);
  if (data.lieu) doc.text(`Lieu : ${data.lieu}`);
  doc.text(`Statut : ${statusLabels[data.matchStatus] ?? data.matchStatus}`);
  doc.text(`Formation : ${data.formation ?? '-'}`);
  doc.text(
    `Score : ${data.homeScore} - ${data.awayScore} (${data.isHome ? 'Domicile' : 'Extérieur'})`
  );

  // Lineup
  doc.moveDown(1).fontSize(14).fillColor('#0B5D3B').text('Composition');
  if (data.lineup.length === 0) {
    doc.fontSize(11).fillColor('#64748B').text('Aucune composition enregistrée.');
  } else {
    for (const item of data.lineup) {
      const name = `${item.firstName} ${item.lastName}`;
      const num = item.numeroMaillot != null ? ` #${item.numeroMaillot}` : '';
      const status = item.status === 'STARTER' ? 'Titulaire' : item.status === 'SUBSTITUTE' ? 'Remplaçant' : 'Non retenu';
      doc.fontSize(11).fillColor('#0F172A').text(`• ${name}${num} — ${status}`);
    }
  }

  // Events
  doc.moveDown(1).fontSize(14).fillColor('#0B5D3B').text('Événements');
  if (data.events.length === 0) {
    doc.fontSize(11).fillColor('#64748B').text('Aucun événement.');
  } else {
    for (const ev of data.events) {
      const label = eventLabels[ev.eventType] ?? ev.eventType;
      const minute = `${ev.minute}'`;
      const player = ev.playerName ?? '-';
      const comment = ev.comment != null ? ` — ${ev.comment}` : '';
      doc.fontSize(11).fillColor('#0F172A').text(`${minute}  ${player}  (${label})${comment}`);
    }
  }

  // Player stats table
  doc.moveDown(1).fontSize(14).fillColor('#0B5D3B').text('Statistiques joueurs');
  if (data.stats.length === 0) {
    doc.fontSize(11).fillColor('#64748B').text('Aucune statistique.');
  } else {
    drawStatsTable(doc, data.stats);
  }

  // Evaluations
  doc.moveDown(1).fontSize(14).fillColor('#0B5D3B').text('Évaluations du coach');
  if (data.evaluations.length === 0) {
    doc.fontSize(11).fillColor('#64748B').text('Aucune évaluation.');
  } else {
    for (const e of data.evaluations) {
      const note = e.note != null ? `${e.note.toFixed(1)}/10` : '-';
      const comment = e.commentaire != null ? ` — ${e.commentaire}` : '';
      doc.fontSize(11).fillColor('#0F172A').text(`• ${e.playerName} : ${note}${comment}`);
    }
  }

  doc.moveDown(2);
  doc.fontSize(9).fillColor('#64748B').text(
    `Document généré automatiquement par FootTech le ${new Date().toLocaleString('fr-FR')}`,
    { align: 'center' }
  );
}

function drawStatsTable(
  doc: PDFKit.PDFDocument,
  stats: MatchReportData['stats']
): void {
  const startY = doc.y;
  const left = 50;
  const right = 545;
  const colWidths = [200, 55, 55, 60, 70, 55, 55];
  const headers = ['Joueur', 'Min', 'Buts', 'PD', 'Min. enc', 'JC', 'JR'];

  doc.fontSize(9).fillColor('#0F172A');
  let x = left;
  for (let i = 0; i < headers.length; i++) {
    doc.text(headers[i]!, x, startY, { width: colWidths[i]!, align: 'left' });
    x += colWidths[i]!;
  }
  doc.moveTo(left, startY + 14).lineTo(right, startY + 14).strokeColor('#0B5D3B').stroke();

  let y = startY + 20;
  for (const row of stats) {
    const values = [
      `${row.playerName}`,
      `${row.minutesPlayed}`,
      `${row.goals}`,
      `${row.assists}`,
      `${row.goalsConceded}`,
      `${row.yellowCards}`,
      `${row.redCards}`,
    ];
    x = left;
    for (let i = 0; i < values.length; i++) {
      doc.text(values[i]!, x, y, { width: colWidths[i]!, align: 'left' });
      x += colWidths[i]!;
    }
    y += 16;
    if (y > 760) {
      doc.addPage();
      y = 50;
    }
  }
  doc.y = y;
}
