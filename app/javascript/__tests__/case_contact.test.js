/* eslint-env jest */

require('jest')

test("case_contact doesn't run on pages without case contact form", () => {
  // Set up our document body
  const name = 'hello'

  document.body.innerHTML =
    `<div>${name}</div>`

  require('../src/case_contact')

  expect(() => {
    Console.log("Changeeeeee")
    window.onload()
  }).not.toThrow()
})
