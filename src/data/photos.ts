// ABOUTME: 2025–2026 photo bank — image imports, bilingual alt text, and object-fit focal points.
// ABOUTME: Placement per photo-placement.md; every photo shows people, so never overlay text on one.
import type { ImageMetadata } from 'astro';
import delegationStage from '../assets/photos/jmcc-2026-delegation-stage.jpg';
import delegationGala from '../assets/photos/jmcc-2026-delegation-gala.jpg';
import delegationArch from '../assets/photos/jdc-2026-delegation-arch.jpg';
import spiritOutdoor from '../assets/photos/jdc-2026-spirit-outdoor.jpg';
import judgesHandshake from '../assets/photos/jmcc-2026-judges-handshake.jpg';
import celebrationTrio from '../assets/photos/jdc-2026-celebration-trio.jpg';
import foPodiumTrophy from '../assets/photos/fo-2026-podium-trophy.jpg';

// Focal points are tuned so faces survive a short band crop — the percentage is roughly where
// the heads sit in the frame. Re-check them if a band's height changes.
// Publication rights confirmed 2026-08-18 for all four photographers ("Vince Noël
// Photographe", "Guillaume", "Karl-Erik", "Jean-Daniel"). No on-page credit is required,
// so there is no `credit` field. Add one only if that arrangement changes.
interface Photo {
  src: ImageMetadata;
  alt: { en: string; fr: string };
  focal: string;
}

export const photos = {
  delegationStage: {
    src: delegationStage,
    alt: {
      en: 'The JMCC delegation on stage beneath the John Molson Competition Committee banner',
      fr: 'La délégation du JMCC sur scène sous la bannière du John Molson Competition Committee',
    },
    focal: 'center 45%',
  },
  delegationGala: {
    src: delegationGala,
    alt: {
      en: 'The full JMCC delegation with arms raised, wearing JMCC scarves at the season banquet',
      fr: 'Toute la délégation du JMCC, bras levés et foulards du JMCC, au banquet de fin de saison',
    },
    focal: 'center 48%',
  },
  delegationArch: {
    src: delegationArch,
    alt: {
      en: 'JMCC delegates gathered outdoors in winter gear and scarves at Jeux du Commerce 2026',
      fr: 'Des délégués du JMCC réunis dehors en tenue d’hiver et foulards aux Jeux du Commerce 2026',
    },
    focal: 'center 45%',
  },
  spiritOutdoor: {
    src: spiritOutdoor,
    alt: {
      en: 'JMCC delegates in costume performing a spirit routine outdoors at Jeux du Commerce 2026',
      fr: 'Des délégués du JMCC en costume lors d’une routine d’esprit d’équipe aux Jeux du Commerce 2026',
    },
    focal: 'center 35%',
  },
  judgesHandshake: {
    src: judgesHandshake,
    alt: {
      en: 'A JMCC delegate shaking hands with judges after presenting a case',
      fr: 'Un délégué du JMCC serrant la main des juges après avoir présenté un cas',
    },
    focal: '35% 35%',
  },
  celebrationTrio: {
    src: celebrationTrio,
    alt: {
      en: 'Three JMCC delegates cheering with arms raised as results are announced',
      fr: 'Trois délégués du JMCC célébrant bras levés à l’annonce des résultats',
    },
    focal: 'center 45%',
  },
  foPodiumTrophy: {
    src: foPodiumTrophy,
    alt: {
      en: 'JMCC delegates on stage holding a trophy at the Financial Open 2026',
      fr: 'Des délégués du JMCC sur scène avec un trophée à l’Omnium financier 2026',
    },
    focal: 'center 30%',
  },
} satisfies Record<string, Photo>;
