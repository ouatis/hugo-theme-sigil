#!/usr/bin/env node
// Original schematic geometry. No third-party drawing library or runtime.
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const round = value => Number(value.toFixed(2));
const p = ([x, y, z = 0]) => [round(320 + (x - y) * .82), round(240 + (x + y) * .4 - z)];
const points = list => list.map((point, index) => `${index ? 'L' : 'M'}${p(point).join(' ')}`).join(' ');
const face = (list, tone) => `<path class="sg-anatomy__${tone}" d="${points(list)}Z"/>`;
const line = (list, tone = 'print') => `<path class="sg-anatomy__${tone}" d="${points(list)}"/>`;
function slab(x, y, w, d, z, h, top = 'top') {
    const a = [x,y,z], b = [x+w,y,z], c = [x+w,y+d,z], e = [x,y+d,z];
    const up = point => [point[0], point[1], point[2]+h];
    return `<g class="sg-anatomy__solid">${face([e,c,up(c),up(e)],'side')}${face([b,c,up(c),up(b)],'end')}${face([up(a),up(b),up(c),up(e)],top)}</g>`;
}
function marker(point, number) {
    const [cx, cy] = p(point);
    return `<circle class="sg-anatomy__marker" cx="${cx}" cy="${cy}" r="8"/><text class="sg-anatomy__marker-number" x="${cx}" y="${cy + 3}" text-anchor="middle">${number}</text>`;
}
function part(key, contents) {
    return `<g class="sg-anatomy__part sg-anatomy__part-${key}${key === 'body' ? ' is-selected' : ''}" data-part="${key}">${contents}</g>`;
}
let contents = `<ellipse class="sg-anatomy__shadow" cx="320" cy="336" rx="184" ry="52"/>`;
contents += slab(-114,-154,234,316,0,5);
let header = slab(-108,-148,220,40,8,4,'paper');
header += face([[-96,-135,13],[-88,-139,13],[-80,-135,13],[-88,-131,13]],'ink');
for (const x of [-52,-8,37,78]) header += line([[x,-131,13],[x+25,-131,13]],'rule');
header += marker([-96,-150,17],1);
contents += part('header',header);
let body = slab(-108,-101,174,220,8,4,'paper');
body += line([[-88,-83,13],[43,-83,13]],'headline');
body += line([[-88,-66,13],[-16,-66,13]],'print');
for (const start of [-42,9]) {
    for (let i=0;i<4;i++) body += line([[-88,start+i*10,13],[i===3 ? 4 : 48,start+i*10,13]]);
}
body += slab(-88,61,131,33,12,.8);
for(let i=0;i<3;i++) body += line([[-81,68+i*8,13],[i===2 ? -9 : 31,68+i*8,13]]);
body += marker([-96,-65,16],2);
contents += part('body',body);
let notes = '';
for(const y of [-83,-15,54]) {
    notes += slab(74,y,38,41,8,3,'paper');
    for(let i=0;i<3;i++) notes += line([[80,y+11+i*9,12],[i===2 ? 99 : 107,y+11+i*9,12]]);
}
notes += marker([93,-94,16],3);
contents += part('notes',notes);
let toc = slab(128,-140,54,113,16,3,'paper');
for(let i=0;i<7;i++) toc += line([[135,-128+i*13,20],[i%2 ? 163 : 174,-128+i*13,20]],i===2 ? 'headline' : 'print');
toc += marker([138,-151,22],4);
contents += part('toc',toc);
let footer = slab(-108,128,220,26,8,4,'paper');
footer += line([[-89,139,13],[-22,139,13]],'rule');
footer += line([[-10,139,13],[30,139,13]],'print');
footer += line([[43,139,13],[94,139,13]],'print');
footer += marker([-95,154,15],5);
contents += part('footer',footer);
const svg = `<svg xmlns="http://www.w3.org/2000/svg" class="sg-page-anatomy__drawing" viewBox="0 60 680 400" width="680" height="400" aria-hidden="true" focusable="false"><title>A schematic article page, separated into five roles</title>${contents}</svg>\n`;
if(process.argv.includes('--write')) {
    const directory=fileURLToPath(new URL('../assets/figures/',import.meta.url));
    mkdirSync(directory,{recursive:true});
    writeFileSync(`${directory}/page-anatomy.svg`,svg);
    console.log('Built the original five-part page schematic.');
} else console.log(svg);
