// firestore.rules — emülatörde, gerçek kural motoruyla.
//
//     cd firebase_tests && npm install && npm test
//
// Hesap gerekmez: "demo-" önekli proje emülatörde çevrimdışı çalışır.
//
// Uygulamanın sunucuya yazdığı tek kişisel veri, sahibin paylaşmayı seçtiği
// yakınlık durumu. Erişim sahibin `partners` listesine bağlı ve o listeye
// yalnızca sahip ekleme yapabiliyor; partner yalnızca kendini çıkarabiliyor.
// Bu dosya kuralların bunu gerçekten sağladığını sınıyor — kod tarafındaki
// testler sahte bir sunucuyla çalışıyor ve kuralları göremiyor.
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayRemove,
  arrayUnion,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-nilu',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

/** Kuralları atlayarak başlangıç verisi yazar. */
async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

const durum = { sexualDesire: 'feel_closer', affectionNeeds: ['hug'], isShared: true };

describe('intimacy/{uid}: paylaşılan durum', () => {
  test('sahip kendi durumunu yazar ve siler', async () => {
    await assertSucceeds(setDoc(doc(db('sahip'), 'intimacy/sahip'), durum));
    await assertSucceeds(deleteDoc(doc(db('sahip'), 'intimacy/sahip')));
  });

  test('başkası sahibin adına yazamaz', async () => {
    await assertFails(setDoc(doc(db('baska'), 'intimacy/sahip'), durum));
  });

  test('onaylı partner okur, yazamaz', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'users/sahip'), { partners: ['partner'] });
      await setDoc(doc(fs, 'intimacy/sahip'), durum);
    });
    await assertSucceeds(getDoc(doc(db('partner'), 'intimacy/sahip')));
    await assertFails(setDoc(doc(db('partner'), 'intimacy/sahip'), durum));
    await assertFails(deleteDoc(doc(db('partner'), 'intimacy/sahip')));
  });

  test('onay bekleyen ya da listede olmayan okuyamaz', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'users/sahip'), { partners: ['partner'] });
      await setDoc(doc(fs, 'intimacy/sahip'), durum);
    });
    await assertFails(getDoc(doc(db('bekleyen'), 'intimacy/sahip')));
  });

  test('sahibin profili yoksa kimse okuyamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'intimacy/sahip'), durum));
    await assertFails(getDoc(doc(db('partner'), 'intimacy/sahip')));
  });

  test('oturumsuz hiçbir şey yapılamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'intimacy/sahip'), durum));
    await assertFails(getDoc(doc(db(null), 'intimacy/sahip')));
    await assertFails(setDoc(doc(db(null), 'intimacy/sahip'), durum));
  });
});

describe('users/{uid}: partner listesi', () => {
  test('sahip listeyi değiştirir (tek partner)', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'users/sahip'), { partners: ['eski'] }));
    await assertSucceeds(updateDoc(doc(db('sahip'), 'users/sahip'), { partners: ['yeni'] }));
  });

  test('partner kendini listeye ekleyemez', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'users/sahip'), { partners: [] }));
    await assertFails(
      updateDoc(doc(db('saldirgan'), 'users/sahip'), { partners: arrayUnion('saldirgan') }),
    );
  });

  test('partner yalnızca kendini çıkarabilir', async () => {
    await seed(async (fs) =>
      setDoc(doc(fs, 'users/sahip'), { partners: ['partner', 'diger'] }),
    );
    await assertSucceeds(
      updateDoc(doc(db('partner'), 'users/sahip'), { partners: arrayRemove('partner') }),
    );
    // Başkasını çıkaramaz.
    await assertFails(
      updateDoc(doc(db('partner'), 'users/sahip'), { partners: arrayRemove('diger') }),
    );
  });

  test('kendini çıkarırken başka alan değiştiremez', async () => {
    await seed(async (fs) =>
      setDoc(doc(fs, 'users/sahip'), { partners: ['partner'], hasPartner: true }),
    );
    await assertFails(
      updateDoc(doc(db('partner'), 'users/sahip'), {
        partners: arrayRemove('partner'),
        hasPartner: false,
      }),
    );
  });

  test('listede olmayanın "çıkarma"sı hiçbir şeyi değiştirmez', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'users/sahip'), { partners: ['partner'] }));
    // Onay gelmeden ayrılan partner: kurallar izin veriyor ama liste aynı.
    await assertSucceeds(
      updateDoc(doc(db('bekleyen'), 'users/sahip'), { partners: arrayRemove('bekleyen') }),
    );
    let partners;
    await env.withSecurityRulesDisabled(async (ctx) => {
      partners = (await getDoc(doc(ctx.firestore(), 'users/sahip'))).data().partners;
    });
    if (JSON.stringify(partners) !== JSON.stringify(['partner'])) {
      throw new Error(`liste değişti: ${JSON.stringify(partners)}`);
    }
  });

  test('başkasının profilini okuyamaz, silemez, oluşturamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'users/sahip'), { partners: ['partner'] }));
    await assertFails(getDoc(doc(db('partner'), 'users/sahip')));
    await assertFails(deleteDoc(doc(db('partner'), 'users/sahip')));
    await assertFails(setDoc(doc(db('partner'), 'users/yeni'), { partners: [] }));
  });

  test('eski günlük kayıtları: yazılamaz, sahibi silebilir', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'users/sahip/logs/2026-10-01'), { notes: 'x' }));
    await assertFails(setDoc(doc(db('sahip'), 'users/sahip/logs/2026-10-02'), { notes: 'y' }));
    await assertSucceeds(getDoc(doc(db('sahip'), 'users/sahip/logs/2026-10-01')));
    await assertSucceeds(deleteDoc(doc(db('sahip'), 'users/sahip/logs/2026-10-01')));
    await assertFails(getDoc(doc(db('partner'), 'users/sahip/logs/2026-10-01')));
  });
});

describe('pairingTokens: davet kodu ve istekler', () => {
  test('kod yalnızca kendi adına oluşturulur', async () => {
    await assertSucceeds(setDoc(doc(db('sahip'), 'pairingTokens/KOD'), { ownerUid: 'sahip' }));
    await assertFails(setDoc(doc(db('sahip'), 'pairingTokens/KOD2'), { ownerUid: 'baska' }));
  });

  test('kodu bilen çözer; liste kapalı; güncelleme yok', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' }));
    await assertSucceeds(getDoc(doc(db('partner'), 'pairingTokens/KOD')));
    await assertFails(getDocs(collection(db('partner'), 'pairingTokens')));
    await assertFails(updateDoc(doc(db('sahip'), 'pairingTokens/KOD'), { ownerUid: 'sahip' }));
  });

  test('kodu yalnızca sahibi iptal eder', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' }));
    await assertFails(deleteDoc(doc(db('partner'), 'pairingTokens/KOD')));
    await assertSucceeds(deleteDoc(doc(db('sahip'), 'pairingTokens/KOD')));
  });

  test('istek yalnızca kendi adına bırakılır', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' }));
    await assertSucceeds(
      setDoc(doc(db('partner'), 'pairingTokens/KOD/requests/partner'), {
        requestedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(db('partner'), 'pairingTokens/KOD/requests/baskasi'), {
        requestedAt: serverTimestamp(),
      }),
    );
  });

  test('istekleri sahip görür ve siler; istekte bulunan kendininkini geri çeker', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' });
      await setDoc(doc(fs, 'pairingTokens/KOD/requests/partner'), { requestedAt: 1 });
      await setDoc(doc(fs, 'pairingTokens/KOD/requests/diger'), { requestedAt: 2 });
    });
    await assertSucceeds(getDocs(collection(db('sahip'), 'pairingTokens/KOD/requests')));
    await assertSucceeds(deleteDoc(doc(db('sahip'), 'pairingTokens/KOD/requests/diger')));
    await assertSucceeds(deleteDoc(doc(db('partner'), 'pairingTokens/KOD/requests/partner')));
  });

  test('başkasının isteğini göremez, silemez', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' });
      await setDoc(doc(fs, 'pairingTokens/KOD/requests/partner'), { requestedAt: 1 });
    });
    await assertFails(getDoc(doc(db('yabanci'), 'pairingTokens/KOD/requests/partner')));
    await assertFails(deleteDoc(doc(db('yabanci'), 'pairingTokens/KOD/requests/partner')));
  });
});

describe('tanımsız yollar', () => {
  test('her şey kapalı', async () => {
    await assertFails(setDoc(doc(db('sahip'), 'baska/x'), { a: 1 }));
    await assertFails(getDoc(doc(db('sahip'), 'baska/x')));
  });
});
