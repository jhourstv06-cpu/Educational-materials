# EDUCATIONAL MATERIALS — hatua za kuunganisha backend

Tovuti ya sasa imechapishwa kwenye GitHub Pages. Ili iwe mfumo halisi wenye akaunti, PDF, malipo na admin, inahitaji backend. GitHub Pages peke yake haiwezi kuhifadhi taarifa salama au kuthibitisha malipo.

## Backend ya bure: Supabase
1. Fungua https://supabase.com/ na tengeneza project (Free).
2. Nenda SQL Editor, fungua New query, bandika maudhui ya `supabase/schema.sql`, kisha Run.
3. Nenda Project Settings > API. Nakili Project URL na anon/public key.
4. Nenda Authentication > Providers, hakikisha Email imewezeshwa.
5. Jisajili kwenye tovuti kwa akaunti yako. Kisha Supabase > Authentication > Users nakili UUID yako.
6. SQL Editor endesha: `update public.profiles set role = 'admin' where id = 'WEKA-UUID-HAPA';`
7. Hifadhi Project URL na anon key kwa ajili ya kuunganisha kwenye tovuti.

## Malipo
- Bei iliyowekwa ni TSh 500.
- Tigo Pesa: 0773614026.
- Mtumiaji anatuma kumbukumbu ya muamala; hali inabaki pending hadi admin aihakiki na kuidhinisha.
- Huu si uthibitishaji wa moja kwa moja wa Tigo Pesa. Uthibitishaji wa moja kwa moja unahitaji API/ushirikiano rasmi wa mtoa huduma.

## Usalama
- Usitumie kamwe Supabase service_role key kwenye HTML/JavaScript ya tovuti.
- PDF ziko kwenye private bucket; sera za SQL zinaruhusu kusoma bure au baada ya malipo kuidhinishwa.
- Usichapishe taarifa za siri au nywila kwenye GitHub.
