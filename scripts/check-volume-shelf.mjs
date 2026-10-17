// Isolated regression fixtures; no installed packages or network access needed.
import {mkdtempSync,mkdirSync,writeFileSync,readFileSync,rmSync,realpathSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {tmpdir} from 'node:os';
import {basename,dirname,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const root=resolve(fileURLToPath(new URL('..',import.meta.url)));
const tempRoot=realpathSync(tmpdir());
const fixture=mkdtempSync(join(tempRoot,'sigil-volume-shelf-'));
const shortcode='{{< volume-shelf >}}';
const body=`${shortcode}

## First

1. [A](/chapters/a/)
2. [A repeated](/chapters/a/#paragraph)
3. [External A](https://elsewhere.test/chapters/a/)
4. [Missing](/chapters/missing/)
5. [Draft](/chapters/draft/)
6. [Future](/chapters/future/)
7. [Expired](/chapters/expired/)
8. [This catalogue](/catalog/)
9. [Another shelf](/another/)

~~~markdown
## Not a volume
1. [B in a code example](/chapters/b/)
~~~

## Second

10. [B](https://fixture.test/chapters/b/?view=text#paragraph)
11. [B repeated](/chapters/b/)

## Third

12. Pending chapter
`;
const files={
    'hugo.toml':`baseURL = "https://fixture.test/"
theme = ${JSON.stringify(basename(root))}
defaultContentLanguage = "zh-cn"
hasCJKLanguage = true
[languages.zh-cn]
weight = 1
[languages.en]
weight = 2
`,
    'layouts/_default/single.html':'<main>{{ .Content }}</main>',
    'layouts/index.html':'<main>Fixture</main>',
    'content/catalog.md':'---\ntitle: Catalogue\n---\n'+body,
    'content/catalog.en.md':'---\ntitle: Catalogue\n---\n'+body,
    'content/empty.md':'---\ntitle: Empty\n---\n'+shortcode+'\n\n## First\n\n1. Pending\n\n## Second\n\n2. [External](https://elsewhere.test/chapters/a/)\n',
    'content/another.md':'---\ntitle: Another\n---\n'+shortcode+'\n\n## First\n\n1. [A](/chapters/a/)\n',
    'content/chapters/a.md':'---\ntitle: A\n---\nalpha beta gamma\n',
    'content/chapters/b.md':'---\ntitle: B\n---\nalpha beta gamma delta epsilon zeta\n',
    'content/chapters/draft.md':'---\ntitle: Draft\ndraft: true\n---\nThis text must not count.\n',
    'content/chapters/future.md':'---\ntitle: Future\npublishDate: 2099-01-01\n---\nThis text must not count.\n',
    'content/chapters/expired.md':'---\ntitle: Expired\nexpiryDate: 2000-01-01\n---\nThis text must not count.\n',
};
function count(html,key){return [...html.matchAll(new RegExp(`\\bdata-${key}=["']?(\\d+)`,'g'))].map(m=>Number(m[1]));}
try{
    for(const [name,content] of Object.entries(files)){
        const path=join(fixture,name);mkdirSync(dirname(path),{recursive:true});writeFileSync(path,content);
    }
    // Deliberately include all unpublished pages in Hugo's page collection:
    // the shelf must still reject drafts, future pages, and expired pages.
    execFileSync(process.env.HUGO_BIN||'hugo',['--source',fixture,'--themesDir',dirname(root),'--buildDrafts','--buildFuture','--buildExpired','--minify','--quiet'],{stdio:'pipe',timeout:30000});
    for(const path of ['catalog/index.html','en/catalog/index.html']){
        const html=readFileSync(join(fixture,'public',path),'utf8');
        assert.deepEqual(count(html,'words'),[3,6,0],path);
        assert.deepEqual(count(html,'chapters'),[1,1,0],path);
        const widths=[...html.matchAll(/viewBox=["']?15 8 (\d+) 178/g)].map(m=>Number(m[1]));
        assert.deepEqual(widths,[62,71,39],path);
    }
    const empty=readFileSync(join(fixture,'public','empty/index.html'),'utf8');
    assert.deepEqual(count(empty,'words'),[0,0]);
    assert.deepEqual([...empty.matchAll(/viewBox=["']?15 8 (\d+) 178/g)].map(m=>Number(m[1])),[56,56]);
    console.log('PASS: exact word counts; duplicate, placeholder, external, missing, draft, future, expired, self/shelf and fenced-code exclusions; cross-language URLs; neutral fallback.');
}catch(error){
    if(error.stdout)process.stderr.write(error.stdout);
    if(error.stderr)process.stderr.write(error.stderr);
    throw error;
}finally{
    // Remove only the fresh, narrowly named temporary fixture directory.
    const resolved=realpathSync(fixture);
    assert.equal(dirname(resolved),tempRoot);
    assert(basename(resolved).startsWith('sigil-volume-shelf-'));
    rmSync(resolved,{recursive:true,force:true});
}
