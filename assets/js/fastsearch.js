import * as params from '@params';

let fuse; // holds our search engine
let resList = document.getElementById('searchResults');
let sInput = document.getElementById('searchInput');
let sEmpty = document.getElementById('searchEmpty');
let minLabel = document.getElementById('searchbox').getAttribute('data-min') || 'min';
let readPrefix = document.getElementById('searchbox').getAttribute('data-read') || '';
let first, last, current_elem = null
let resultsAvailable = false;

// load our search index
window.onload = function () {
    let xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                let data = JSON.parse(xhr.responseText);
                if (data) {
                    // fuse.js options; check fuse.js website for details
                    let options = {
                        distance: 100,
                        threshold: 0.4,
                        ignoreLocation: true,
                        keys: [
                            'title',
                            'permalink',
                            'summary',
                            'content'
                        ]
                    };
                    if (params.fuseOpts) {
                        options = {
                            isCaseSensitive: params.fuseOpts.iscasesensitive ?? false,
                            includeScore: params.fuseOpts.includescore ?? false,
                            includeMatches: params.fuseOpts.includematches ?? false,
                            minMatchCharLength: params.fuseOpts.minmatchcharlength ?? 1,
                            shouldSort: params.fuseOpts.shouldsort ?? true,
                            findAllMatches: params.fuseOpts.findallmatches ?? false,
                            keys: params.fuseOpts.keys ?? ['title', 'permalink', 'summary', 'content'],
                            location: params.fuseOpts.location ?? 0,
                            threshold: params.fuseOpts.threshold ?? 0.4,
                            distance: params.fuseOpts.distance ?? 100,
                            ignoreLocation: params.fuseOpts.ignorelocation ?? true
                        }
                    }
                    fuse = new Fuse(data, options); // build the index from the json file
                }
            } else {
                console.log(xhr.responseText);
            }
        }
    };
    xhr.open('GET', "../index.json");
    xhr.send();
}

function activeToggle(ae) {
    document.querySelectorAll('.focus').forEach(function (element) {
        // rm focus class
        element.classList.remove("focus")
    });
    if (ae) {
        ae.focus()
        document.activeElement = current_elem = ae;
        ae.parentElement.classList.add("focus")
    } else {
        document.activeElement.parentElement.classList.add("focus")
    }
}

function reset() {
    resultsAvailable = false;
    resList.innerHTML = sInput.value = ''; // clear inputbox and searchResults
    if (sEmpty) sEmpty.hidden = true; // hide the no-results whisper
    sInput.focus(); // shift focus to input box
}

// 搜索结果条目:复用首页 sg-entry 的行式结构(编号+日期+主栏+箭头),
// 样式随 sigil.css 全量继承;<a> 必须保持为 li 的末子节点(键盘导航依赖 lastChild)
function entryHTML(item, rank) {
    const number = String(rank + 1).padStart(2, '0');
    const iso = item.date ? item.date.replace(/\./g, '-') : '';
    const meta =
        (item.category ? `<span class="sg-entry__category">${item.category}</span>` : '') +
        (item.readingtime ? `<span class="sg-entry__time">${item.readingtime} ${minLabel}</span>` : '');
    return `<li class="sg-entry">` +
        `<p class="sg-entry__number" aria-hidden="true">${number}</p>` +
        (item.date ? `<time class="sg-entry__date"${iso ? ` datetime="${iso}"` : ''}>${item.date}</time>` : '<span class="sg-entry__date"></span>') +
        `<div class="sg-entry__main"><h3>${item.title}</h3>` +
        (meta ? `<div class="sg-entry__meta">${meta}</div>` : '') +
        `</div>` +
        `<span class="sg-entry__arrow" aria-hidden="true">→</span>` +
        `<a class="sg-entry__link" href="${item.permalink}" aria-label="${readPrefix}${item.title}"></a></li>`;
}

// execute search as each character is typed
sInput.onkeyup = function (e) {
    // run a search query (for "term") every time a letter is typed
    // in the search box
    if (fuse) {
        let results;
        if (params.fuseOpts) {
            results = fuse.search(this.value.trim(), {limit: params.fuseOpts.limit}); // the actual query being run using fuse.js along with options
        } else {
            results = fuse.search(this.value.trim()); // the actual query being run using fuse.js
        }
        if (results.length !== 0) {
            // build our html if result exists
            let resultSet = ''; // our results bucket

            results.forEach(function (r, rank) {
                resultSet += entryHTML(r.item, rank);
            });

            resList.innerHTML = resultSet;
            resultsAvailable = true;
            first = resList.firstChild;
            last = resList.lastChild;
        } else {
            resultsAvailable = false;
            resList.innerHTML = '';
        }
        // whisper only when a real query came back empty, not while typing blanks
        if (sEmpty) sEmpty.hidden = !(this.value.trim() !== '' && results.length === 0);
    }
}

sInput.addEventListener('search', function (e) {
    // clicked on x
    if (!this.value) reset()
})

// kb bindings
document.onkeydown = function (e) {
    let key = e.key;
    let ae = document.activeElement;

    let inbox = document.getElementById("searchbox").contains(ae)

    if (ae === sInput) {
        let elements = document.getElementsByClassName('focus');
        while (elements.length > 0) {
            elements[0].classList.remove('focus');
        }
    } else if (current_elem) ae = current_elem;

    // 输入法组合期(选词确认)的一切按键都不属于搜索导航,
    // 否则拼音敲完按 Enter 上屏会直接跳进第一条结果
    if (e.isComposing) return;

    if (key === "Escape") {
        reset()
    } else if (!resultsAvailable || !inbox) {
        return
    } else if (key === "Enter") {
        // 回车直达:焦点在结果上开高亮项,否则开第一条
        let target = (ae && resList.contains(ae)) ? ae : first.lastChild;
        if (target) {
            e.preventDefault();
            target.click();
        }
    } else if (key === "ArrowDown") {
        e.preventDefault();
        if (ae == sInput) {
            // if the currently focused element is the search input, focus the <a> of first <li>
            activeToggle(resList.firstChild.lastChild);
        } else if (ae.parentElement != last) {
            // if the currently focused element's parent is last, do nothing
            // otherwise select the next search result
            activeToggle(ae.parentElement.nextSibling.lastChild);
        }
    } else if (key === "ArrowUp") {
        e.preventDefault();
        if (ae.parentElement == first) {
            // if the currently focused element is first item, go to input box
            activeToggle(sInput);
        } else if (ae != sInput) {
            // if the currently focused element is input box, do nothing
            // otherwise select the previous search result
            activeToggle(ae.parentElement.previousSibling.lastChild);
        }
    } else if (key === "ArrowRight") {
        ae.click(); // click on active link
    }
}
