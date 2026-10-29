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
  Timestamp,
  updateDoc,
  writeBatch,
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

// Oturumlar Apple ya da Google hesabı: kurallar anonim oturumu kabul etmiyor.
const db = (uid) =>
  uid
    ? env
        .authenticatedContext(uid, {
          firebase: { sign_in_provider: 'apple.com', identities: { 'apple.com': ['1'] } },
        })
        .firestore()
    : env.unauthenticatedContext().firestore();

// Eski sürümlerin partner eşleşmesi için açtığı anonim oturum.
const anonim = (uid) =>
  env
    .authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous', identities: {} } })
    .firestore();

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

  // Partner onayı kendi isteğinin silinmesinden öğreniyor: istek dururken
  // de silindikten sonra da okuyabilmeli.
  test('istekte bulunan kendi isteğini okur, silindikten sonra da', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' });
      await setDoc(doc(fs, 'pairingTokens/KOD/requests/partner'), { requestedAt: 1 });
    });
    await assertSucceeds(getDoc(doc(db('partner'), 'pairingTokens/KOD/requests/partner')));
    await assertSucceeds(deleteDoc(doc(db('sahip'), 'pairingTokens/KOD/requests/partner')));
    await assertSucceeds(getDoc(doc(db('partner'), 'pairingTokens/KOD/requests/partner')));
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

// Davet bağlantısı: tek kullanımlık, bir saatlik, ilk açana bağlı.
describe('pairingTokens: davet bağlantısı', () => {
  const davet = (dakikaOnce = 0) => ({
    ownerUid: 'sahip',
    oneTime: true,
    createdAt: Timestamp.fromMillis(Date.now() - dakikaOnce * 60 * 1000),
  });
  const istekVeKullan = (uid) => {
    const fs = db(uid);
    return writeBatch(fs)
      .update(doc(fs, 'pairingTokens/DAVET'), { usedBy: uid })
      .set(doc(fs, 'pairingTokens/DAVET/requests/' + uid), { requestedAt: serverTimestamp() })
      .commit();
  };

  test('sahip davet açar; saat sunucunun, fazladan alan yok', async () => {
    await assertSucceeds(
      setDoc(doc(db('sahip'), 'pairingTokens/DAVET'), {
        ownerUid: 'sahip',
        oneTime: true,
        createdAt: serverTimestamp(),
      }),
    );
    // İstemci saati yazılamaz: süre uzatılabilirdi.
    await assertFails(
      setDoc(doc(db('sahip'), 'pairingTokens/D2'), {
        ownerUid: 'sahip',
        oneTime: true,
        createdAt: Timestamp.fromMillis(Date.now() + 24 * 3600 * 1000),
      }),
    );
    await assertFails(
      setDoc(doc(db('sahip'), 'pairingTokens/D3'), { ownerUid: 'sahip', usedBy: 'sahip' }),
    );
  });

  test('ilk açan kullanır ve istek bırakır; ikinci kişi kullanamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/DAVET'), davet()));
    await assertSucceeds(istekVeKullan('partner'));
    await assertFails(istekVeKullan('baskasi'));
    await assertFails(
      setDoc(doc(db('baskasi'), 'pairingTokens/DAVET/requests/baskasi'), {
        requestedAt: serverTimestamp(),
      }),
    );
  });

  test('aynı kişi de bağlantıyı ikinci kez kullanamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/DAVET'), davet()));
    await assertSucceeds(istekVeKullan('partner'));
    await assertSucceeds(deleteDoc(doc(db('sahip'), 'pairingTokens/DAVET/requests/partner')));
    await assertFails(istekVeKullan('partner'));
  });

  test('kullanmadan istek bırakılamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/DAVET'), davet()));
    await assertFails(
      setDoc(doc(db('partner'), 'pairingTokens/DAVET/requests/partner'), {
        requestedAt: serverTimestamp(),
      }),
    );
  });

  test('bir saat geçince kullanılamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/DAVET'), davet(61)));
    await assertFails(istekVeKullan('partner'));
  });

  test('yalnızca kendi adına, başka alana dokunmadan; sahip kendini ekleyemez', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/DAVET'), davet()));
    await assertFails(updateDoc(doc(db('partner'), 'pairingTokens/DAVET'), { usedBy: 'baskasi' }));
    await assertFails(
      updateDoc(doc(db('partner'), 'pairingTokens/DAVET'), {
        usedBy: 'partner',
        ownerUid: 'partner',
      }),
    );
    await assertFails(updateDoc(doc(db('sahip'), 'pairingTokens/DAVET'), { usedBy: 'sahip' }));
  });

  test('QR kodu kullanılmış sayılamaz; isteği eskisi gibi', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/KOD'), { ownerUid: 'sahip' }));
    await assertFails(updateDoc(doc(db('partner'), 'pairingTokens/KOD'), { usedBy: 'partner' }));
    await assertSucceeds(
      setDoc(doc(db('partner'), 'pairingTokens/KOD/requests/partner'), {
        requestedAt: serverTimestamp(),
      }),
    );
  });

  test('olmayan koda istek bırakılamaz', async () => {
    await assertFails(
      setDoc(doc(db('partner'), 'pairingTokens/YOK/requests/partner'), {
        requestedAt: serverTimestamp(),
      }),
    );
  });
});

describe('syncData/{uid}: bulut kopyası', () => {
  // Apple ya da Google ile giriş yapmış hesabın kimlik jetonu.
  const hesap = (uid, saglayici = 'apple.com') =>
    env
      .authenticatedContext(uid, {
        firebase: { sign_in_provider: saglayici, identities: { [saglayici]: ['1'] } },
      })
      .firestore();
  const meta = { version: 'v1', hash: 'abc', chunkCount: 1, schema: 1, disabled: false, updatedAt: serverTimestamp() };
  const parca = { index: 0, data: '{"format":"nilu-sync"}' };

  test('Apple ile giren sahip yazar, okur, siler', async () => {
    const fs = hesap('ada');
    await assertSucceeds(setDoc(doc(fs, 'syncData/ada/chunks/0'), parca));
    await assertSucceeds(setDoc(doc(fs, 'syncData/ada'), meta));
    await assertSucceeds(getDoc(doc(fs, 'syncData/ada')));
    await assertSucceeds(getDoc(doc(fs, 'syncData/ada/chunks/0')));
    await assertSucceeds(deleteDoc(doc(fs, 'syncData/ada/chunks/0')));
    await assertSucceeds(deleteDoc(doc(fs, 'syncData/ada')));
  });

  test('Google ile giren sahip de', async () => {
    const fs = hesap('ada', 'google.com');
    await assertSucceeds(setDoc(doc(fs, 'syncData/ada'), meta));
    await assertSucceeds(getDoc(doc(fs, 'syncData/ada')));
  });

  test('oturumun sağlayıcısı değil bağlı kimlikler sayılıyor', async () => {
    const fs = env
      .authenticatedContext('ada', {
        firebase: { sign_in_provider: 'anonymous', identities: { 'apple.com': ['1'] } },
      })
      .firestore();
    await assertSucceeds(setDoc(doc(fs, 'syncData/ada'), meta));
  });

  test('anonim kimlik kendi uid\'sinde bile okuyamaz, yazamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'syncData/ada'), meta));
    const fs = anonim('ada');
    await assertFails(getDoc(doc(fs, 'syncData/ada')));
    await assertFails(setDoc(doc(fs, 'syncData/ada'), meta));
    await assertFails(setDoc(doc(fs, 'syncData/ada/chunks/0'), parca));
  });

  test('başka hesap ve onaylı partner bile okuyamaz', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'users/ada'), { partners: ['partner'] });
      await setDoc(doc(fs, 'syncData/ada'), meta);
      await setDoc(doc(fs, 'syncData/ada/chunks/0'), parca);
    });
    for (const fs of [hesap('baska'), anonim('partner'), hesap('partner')]) {
      await assertFails(getDoc(doc(fs, 'syncData/ada')));
      await assertFails(getDoc(doc(fs, 'syncData/ada/chunks/0')));
      await assertFails(getDocs(collection(fs, 'syncData/ada/chunks')));
      await assertFails(setDoc(doc(fs, 'syncData/ada'), meta));
      await assertFails(deleteDoc(doc(fs, 'syncData/ada')));
    }
  });

  test('oturumsuz hiçbir şey yapılamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'syncData/ada'), meta));
    await assertFails(getDoc(doc(db(null), 'syncData/ada')));
    await assertFails(setDoc(doc(db(null), 'syncData/ada'), meta));
  });

  test('tanımsız alan ve geçersiz parça sayısı reddediliyor', async () => {
    const fs = hesap('ada');
    await assertFails(setDoc(doc(fs, 'syncData/ada'), { ...meta, fazla: 1 }));
    await assertFails(setDoc(doc(fs, 'syncData/ada'), { ...meta, chunkCount: -1 }));
    await assertFails(setDoc(doc(fs, 'syncData/ada'), { ...meta, chunkCount: '1' }));
    await assertFails(setDoc(doc(fs, 'syncData/ada/chunks/0'), { ...parca, fazla: 1 }));
    await assertFails(setDoc(doc(fs, 'syncData/ada/chunks/0'), { index: 0, data: 42 }));
  });

  test('"kapatıldı" işareti sağlık verisi olmadan yazılır', async () => {
    const fs = hesap('ada');
    await assertSucceeds(
      setDoc(doc(fs, 'syncData/ada'), { disabled: true, chunkCount: 0, schema: 1, updatedAt: serverTimestamp() }),
    );
  });
});

describe('tanımsız yollar', () => {
  test('her şey kapalı', async () => {
    await assertFails(setDoc(doc(db('sahip'), 'baska/x'), { a: 1 }));
    await assertFails(getDoc(doc(db('sahip'), 'baska/x')));
  });
});

describe('anonim oturum', () => {
  // Partner eşleşmesi artık hesap istiyor. Eski bir sürümden kalmış anonim
  // oturum ne kod açabilir ne istek bırakabilir ne de paylaşılan durumu
  // okuyabilir.
  test('eşleşme kodu açamaz, okuyamaz, istek bırakamaz', async () => {
    await seed(async (fs) => setDoc(doc(fs, 'pairingTokens/KOD1'), { ownerUid: 'ada' }));
    const fs = anonim('partner');
    await assertFails(setDoc(doc(fs, 'pairingTokens/KOD2'), { ownerUid: 'partner' }));
    await assertFails(getDoc(doc(fs, 'pairingTokens/KOD1')));
    await assertFails(setDoc(doc(fs, 'pairingTokens/KOD1/requests/partner'), { at: 1 }));
  });

  test('kendi dokümanına bile yazamaz', async () => {
    const fs = anonim('ada');
    await assertFails(setDoc(doc(fs, 'users/ada'), { partners: [] }));
    await assertFails(setDoc(doc(fs, 'intimacy/ada'), durum));
  });

  test('onaylı partner listesinde olsa da durumu okuyamaz', async () => {
    await seed(async (fs) => {
      await setDoc(doc(fs, 'users/ada'), { partners: ['partner'] });
      await setDoc(doc(fs, 'intimacy/ada'), durum);
    });
    await assertFails(getDoc(doc(anonim('partner'), 'intimacy/ada')));
    await assertSucceeds(getDoc(doc(db('partner'), 'intimacy/ada')));
  });
});
