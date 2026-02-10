import './style.css'
import typescriptLogo from './typescript.svg'
import viteLogo from '/vite.svg'
import { setupCounter } from './counter.ts'

const app = document.getElementById('app') as HTMLDivElement

app.innerHTML = ''

const container = document.createElement('div')
app.appendChild(container)

const viteLink = document.createElement('a')
viteLink.href = 'https://vite.dev'
viteLink.target = '_blank'
container.appendChild(viteLink)

const viteImg = document.createElement('img')
viteImg.src = viteLogo
viteImg.className = 'logo'
viteImg.alt = 'Vite logo'
viteLink.appendChild(viteImg)

const tsLink = document.createElement('a')
tsLink.href = 'https://www.typescriptlang.org/'
tsLink.target = '_blank'
container.appendChild(tsLink)

const tsImg = document.createElement('img')
tsImg.src = typescriptLogo
tsImg.className = 'logo vanilla'
tsImg.alt = 'TypeScript logo'
tsLink.appendChild(tsImg)

const heading = document.createElement('h1')
heading.textContent = 'Vite + TypeScript'
container.appendChild(heading)

const card = document.createElement('div')
card.className = 'card'
container.appendChild(card)

const counterBtn = document.createElement('button')
counterBtn.id = 'counter'
counterBtn.type = 'button'
card.appendChild(counterBtn)

const paragraph = document.createElement('p')
paragraph.className = 'read-the-docs'
paragraph.textContent = 'Click on the Vite and TypeScript logos to learn more'
container.appendChild(paragraph)

setupCounter(counterBtn)
