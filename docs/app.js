const navLinks = Array.from(document.querySelectorAll(".nav-link"));
const sections = navLinks
  .map((link) => document.querySelector(link.getAttribute("href")))
  .filter(Boolean);

const setActive = () => {
  const scrollPosition = window.scrollY + 120;
  let activeIndex = 0;

  sections.forEach((section, index) => {
    if (section.offsetTop <= scrollPosition) {
      activeIndex = index;
    }
  });

  navLinks.forEach((link, index) => {
    if (index === activeIndex) {
      link.classList.add("active");
    } else {
      link.classList.remove("active");
    }
  });
};

window.addEventListener("scroll", setActive);
window.addEventListener("load", setActive);

const year = document.querySelector(".year");
if (year) {
  year.textContent = new Date().getFullYear();
}
