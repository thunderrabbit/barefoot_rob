(function() {
  var questions = [
    {
      q: "When someone asks how you're doing, what's your gut reaction?",
      opts: [
        { text: "I say what I actually feel", score: 0 },
        { text: "I say 'good' or 'fine' without thinking", score: 1 },
        { text: "I know I'm not fine but say it anyway", score: 2 },
        { text: "I genuinely don't know how I feel", score: 3 }
      ]
    },
    {
      q: "How often do you feel a tension or heaviness you can't explain?",
      opts: [
        { text: "Rarely", score: 0 },
        { text: "Sometimes — maybe weekly", score: 1 },
        { text: "Most days", score: 2 },
        { text: "It's basically my default state", score: 3 }
      ]
    },
    {
      q: "When you get angry, what happens next?",
      opts: [
        { text: "I notice it, name it, and decide how to respond", score: 0 },
        { text: "I push it down and move on", score: 1 },
        { text: "It leaks out sideways — sarcasm, silence, short temper", score: 2 },
        { text: "I explode, then feel guilty about it", score: 3 }
      ]
    },
    {
      q: "When was the last time you cried?",
      opts: [
        { text: "Within the past month", score: 0 },
        { text: "Within the past year", score: 1 },
        { text: "I honestly can't remember", score: 2 },
        { text: "I physically can't — even when I want to", score: 3 }
      ]
    },
    {
      q: "If a close friend asked 'what are you afraid of?' — could you answer honestly?",
      opts: [
        { text: "Yes, I could name specific fears", score: 0 },
        { text: "I'd probably deflect with a joke", score: 1 },
        { text: "I'd feel uncomfortable and change the subject", score: 2 },
        { text: "No one in my life would ask me that", score: 3 }
      ]
    },
    {
      q: "How many people in your life know what you're actually going through right now?",
      opts: [
        { text: "Several — I have people I trust", score: 0 },
        { text: "One or two, maybe", score: 1 },
        { text: "People know the surface version", score: 2 },
        { text: "Nobody. I handle things alone.", score: 3 }
      ]
    },
    {
      q: "When something painful happens, what do you do with it?",
      opts: [
        { text: "Talk about it or journal through it", score: 0 },
        { text: "Distract myself until it fades", score: 1 },
        { text: "Tell myself it's not a big deal", score: 2 },
        { text: "Lock it away and keep going", score: 3 }
      ]
    },
    {
      q: "How does your body feel right now?",
      opts: [
        { text: "Relaxed — I can feel my body clearly", score: 0 },
        { text: "Some tension but nothing unusual", score: 1 },
        { text: "Tight — jaw, shoulders, chest", score: 2 },
        { text: "I don't really notice my body much", score: 3 }
      ]
    },
    {
      q: "When someone you care about says 'we need to talk,' what happens inside you?",
      opts: [
        { text: "I'm curious about what they need", score: 0 },
        { text: "Mild anxiety but I can handle it", score: 1 },
        { text: "I brace for impact — walls go up", score: 2 },
        { text: "Dread. I start planning my defense.", score: 3 }
      ]
    },
    {
      q: "If you could change one thing about how you handle emotions, would you?",
      opts: [
        { text: "I'm mostly satisfied with where I am", score: 0 },
        { text: "I'd like to be better but it's not urgent", score: 1 },
        { text: "Yes — I know something needs to shift", score: 2 },
        { text: "I've known for a long time. I just don't know how.", score: 3 }
      ]
    }
  ];

  var results = [
    {
      max: 7,
      title: "Inbox: Under Control",
      emoji: "📭",
      body: "Your emotional inbox is mostly clear. You've got healthy processing habits — you name what you feel, you let people in, and you don't routinely suppress. That doesn't mean life is easy, but it means you're not carrying a hidden backlog. Keep doing what you're doing. And if you want to go deeper, the tools exist when you're ready."
    },
    {
      max: 14,
      title: "Inbox: Getting Full",
      emoji: "📬",
      body: "You're functional — maybe even high-performing — but there's a growing pile of unprocessed stuff underneath. You know how to get through the day, but some emotions are getting deferred, not dealt with. The tension is building quietly. This is the stage where small changes make the biggest difference — before the inbox starts sending error messages."
    },
    {
      max: 21,
      title: "Inbox: Overflowing",
      emoji: "📫",
      body: "Your system is working overtime to keep everything contained. The suppression strategies that used to work — staying busy, pushing through, handling it alone — are starting to crack. You might notice it in your body (tight jaw, chest pressure), in your relationships (distance, irritability), or in a numbness that wasn't always there. Your inbox isn't just full — it's been sending you notifications you've been ignoring. The good news: you're here, which means part of you already knows."
    },
    {
      max: 30,
      title: "Inbox: System Crash Imminent",
      emoji: "🔴",
      body: "You're carrying a lot. The weight you feel isn't weakness — it's the accumulated cost of years of emotions that never got processed. You've been strong for a long time, and that strength got you here. But the same strategy that protected you is now isolating you. This isn't something you need to fix alone. One conversation, one step, one moment of honesty can start clearing the backlog. You don't have to empty the whole inbox today. You just have to open it."
    }
  ];

  var container = document.getElementById('quiz-container');
  var resultsDiv = document.getElementById('quiz-results');
  if (!container) return;

  var currentQ = 0;
  var answers = [];

  function render() {
    if (currentQ >= questions.length) {
      showResults();
      return;
    }

    var q = questions[currentQ];
    var html = '<div style="background:#FFF8EE; padding:30px; border-radius:8px; margin:20px 0;">';
    html += '<p style="font-size:0.9em; color:#888; margin:0 0 8px 0;">Question ' + (currentQ + 1) + ' of ' + questions.length + '</p>';
    html += '<h3 style="margin:0 0 20px 0; font-size:1.3em;">' + q.q + '</h3>';

    for (var i = 0; i < q.opts.length; i++) {
      html += '<button class="quiz-option" data-score="' + q.opts[i].score + '" data-index="' + i + '" style="'
        + 'display:block; width:100%; text-align:left; padding:15px 20px; margin:8px 0;'
        + 'background:white; border:2px solid #ddd; border-radius:6px; cursor:pointer;'
        + 'font-size:1.05em; font-family:inherit; transition: all 0.15s ease;'
        + '">' + q.opts[i].text + '</button>';
    }

    // Progress bar
    var pct = Math.round((currentQ / questions.length) * 100);
    html += '<div style="margin-top:20px; background:#e0e0e0; border-radius:4px; height:6px;">';
    html += '<div style="background:darkgoldenrod; width:' + pct + '%; height:6px; border-radius:4px; transition:width 0.3s ease;"></div>';
    html += '</div>';

    html += '</div>';
    container.innerHTML = html;

    var buttons = container.querySelectorAll('.quiz-option');
    for (var j = 0; j < buttons.length; j++) {
      buttons[j].addEventListener('mouseenter', function() {
        this.style.borderColor = 'darkgoldenrod';
        this.style.background = '#FFFCF5';
      });
      buttons[j].addEventListener('mouseleave', function() {
        this.style.borderColor = '#ddd';
        this.style.background = 'white';
      });
      buttons[j].addEventListener('click', function() {
        var score = parseInt(this.getAttribute('data-score'));
        answers.push(score);
        currentQ++;
        render();
      });
    }
  }

  function showResults() {
    var total = 0;
    for (var i = 0; i < answers.length; i++) total += answers[i];

    var result = results[results.length - 1];
    for (var r = 0; r < results.length; r++) {
      if (total <= results[r].max) {
        result = results[r];
        break;
      }
    }

    container.innerHTML = '';
    resultsDiv.style.display = 'block';

    var html = '<div style="background:#FFF8EE; padding:40px 30px; border-radius:8px; margin:20px 0; text-align:center;">';
    html += '<p style="font-size:3em; margin:0;">' + result.emoji + '</p>';
    html += '<h2 style="margin:10px 0 5px 0;">' + result.title + '</h2>';
    html += '<p style="color:#888; margin:0 0 25px 0;">Score: ' + total + ' / ' + (questions.length * 3) + '</p>';
    html += '<p style="text-align:left; font-size:1.1em; line-height:1.6;">' + result.body + '</p>';

    html += '<div style="margin-top:30px; padding-top:20px; border-top:1px solid #ddd;">';
    html += '<p style="font-weight:bold; margin-bottom:15px;">Want to keep your results?</p>';
    html += '<p style="color:#666; font-size:0.95em;">No spam. No funnel. Just your assessment, in your inbox.</p>';
    html += '<div style="display:flex; gap:10px; max-width:400px; margin:15px auto;">';
    html += '<input type="email" id="results-email" placeholder="your@email.com" style="'
      + 'flex:1; padding:12px 15px; border:2px solid #ddd; border-radius:6px; font-size:1em; font-family:inherit;'
      + '">';
    html += '<button id="send-results" style="'
      + 'padding:12px 20px; background:darkgoldenrod; color:white; border:none; border-radius:6px;'
      + 'font-size:1em; cursor:pointer; font-weight:bold;'
      + '">Send</button>';
    html += '</div>';
    html += '<p id="email-status" style="margin-top:10px; font-size:0.9em;"></p>';
    html += '</div>';

    html += '<div style="margin-top:25px;">';
    html += '<a class="pure-button" style="background-color:darkgoldenrod; font-size:1.2em; color:white; text-decoration:none;" href="https://www.calendly.com/robnugen/discovery">';
    html += 'BOOK A FREE DISCOVERY CALL</a>';
    html += '</div>';

    html += '<div style="margin-top:20px;">';
    html += '<button id="retake-quiz" style="'
      + 'background:none; border:none; color:#888; cursor:pointer; font-size:0.95em; text-decoration:underline;'
      + '">Retake the quiz</button>';
    html += '</div>';

    html += '</div>';
    resultsDiv.innerHTML = html;

    document.getElementById('retake-quiz').addEventListener('click', function() {
      currentQ = 0;
      answers = [];
      resultsDiv.style.display = 'none';
      resultsDiv.innerHTML = '';
      render();
    });

    document.getElementById('send-results').addEventListener('click', function() {
      var email = document.getElementById('results-email').value;
      var status = document.getElementById('email-status');
      if (!email || email.indexOf('@') === -1) {
        status.textContent = 'Please enter a valid email address.';
        status.style.color = '#c00';
        return;
      }
      // For now, store in localStorage and show confirmation
      // TODO: connect to email service (e.g. ConvertKit, Buttondown, or custom endpoint)
      try {
        localStorage.setItem('inbox_overflow_result', JSON.stringify({
          score: total,
          title: result.title,
          email: email,
          date: new Date().toISOString()
        }));
      } catch(e) {}
      status.textContent = "Thanks! (Email delivery coming soon — we've saved your result locally for now.)";
      status.style.color = 'darkgoldenrod';
    });

    // Scroll results into view
    resultsDiv.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  render();
})();
