let reportTypeSelect = document.getElementById('report_type')

reportTypeSelect.addEventListener('change', event => {
    let { target } = event;
    let selectedType = target.value
    let fieldsets = [...document.querySelectorAll('fieldset')]

    fieldsets.forEach(fs => {
        fs.setAttribute('disabled', '')
        fs.classList.add('is-hidden')
    })

    if(selectedType) {
        let fs = document.querySelector(`fieldset#${selectedType}`)
        fs.removeAttribute('disabled')
        fs.classList.remove('is-hidden')
    }
})
