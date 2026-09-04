import { useState, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { Mic, MicOff, Send, X, Volume2, VolumeX, AlertTriangle, CloudRain, ShieldAlert } from 'lucide-react';
import type { ChatMessage } from '../../types/models';
import { clsx } from 'clsx';

const SUGGESTIONS = [
  "Will it rain tomorrow?",
  "Is there any cyclone warning?",
  "Should I irrigate my crops?",
  "Show me the forecast for Chennai"
];

function generateId() {
  return Math.random().toString(36).substring(2, 9);
}

export default function ChatView() {
  const { t, i18n } = useTranslation();
  const [messages, setMessages] = useState<ChatMessage[]>([{
    id: 'welcome',
    role: 'assistant',
    content: 'Hello! I am WeatherGPT. How can I help you with weather, forecasts, alerts, or advisories today?',
    timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    type: 'text'
  }]);
  const [input, setInput] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [speechMuted, setSpeechMuted] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const recognitionRef = useRef<any>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    // Initialize Speech Recognition if available
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (SpeechRecognition) {
      const recognition = new SpeechRecognition();
      recognition.continuous = false;
      recognition.interimResults = false;
      recognition.lang = i18n.language === 'en' ? 'en-US' : i18n.language === 'hi' ? 'hi-IN' : 'ta-IN';
      
      recognition.onresult = (event: any) => {
        const transcript = event.results[0][0].transcript;
        setInput(transcript);
        setIsListening(false);
      };
      
      recognition.onerror = (event: any) => {
        console.error("Speech recognition error", event.error);
        setIsListening(false);
      };

      recognition.onend = () => {
        setIsListening(false);
      };

      recognitionRef.current = recognition;
    }
  }, [i18n.language]);

  const toggleListen = () => {
    if (!recognitionRef.current) {
      alert("Speech recognition is not supported in this browser.");
      return;
    }
    if (isListening) {
      recognitionRef.current.stop();
    } else {
      recognitionRef.current.start();
      setIsListening(true);
    }
  };

  const speak = (text: string) => {
    if (speechMuted || !('speechSynthesis' in window)) return;
    
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = i18n.language === 'en' ? 'en-US' : i18n.language === 'hi' ? 'hi-IN' : 'ta-IN';
    
    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);
    
    window.speechSynthesis.speak(utterance);
  };

  const stopSpeaking = () => {
    window.speechSynthesis.cancel();
    setIsSpeaking(false);
  };

  const handleSend = (text: string = input) => {
    if (!text.trim()) return;
    
    const newMsg: ChatMessage = {
      id: generateId(),
      role: 'user',
      content: text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      type: 'text'
    };
    
    setMessages(prev => [...prev, newMsg]);
    setInput('');
    
    // Simple Intent Matcher for Mock Mode
    setTimeout(() => {
      let responseContent = "I'm sorry, I don't have information on that in demo mode.";
      let type: 'text' | 'weather_card' | 'alert_card' | 'forecast_card' | 'advisory_card' = 'text';
      let data = null;
      
      const q = text.toLowerCase();
      if (q.includes('rain tomorrow') || q.includes('forecast')) {
        responseContent = "Yes, rain showers are expected tomorrow with a high of 32°C and a 30% chance of precipitation.";
        type = 'forecast_card';
      } else if (q.includes('cyclone') || q.includes('warning') || q.includes('alert')) {
        responseContent = "There is an active severe weather alert for Heavy Rainfall in Chennai and Kanchipuram Districts.";
        type = 'alert_card';
      } else if (q.includes('irrigate') || q.includes('crop') || q.includes('agriculture')) {
        responseContent = "Based on the heavy rainfall expected later today, you should consider postponing irrigation to prevent water stagnation.";
        type = 'advisory_card';
      } else if (q.includes('weather') || q.includes('current')) {
        responseContent = "It is currently 31°C and Partly Cloudy in Chennai.";
        type = 'weather_card';
      } else {
        responseContent = "I am operating in demo mode and can only answer queries about the simulated weather, alerts, and advisories for Chennai.";
      }
      
      const reply: ChatMessage = {
        id: generateId(),
        role: 'assistant',
        content: responseContent,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        type,
        data
      };
      
      setMessages(prev => [...prev, reply]);
      speak(responseContent);
    }, 600);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)] max-w-4xl mx-auto bg-white dark:bg-navy-900 rounded-3xl shadow-sm border border-slate-100 dark:border-navy-800 overflow-hidden relative">
      
      {/* Header */}
      <div className="bg-primary-600 text-white px-6 py-4 flex justify-between items-center z-10">
        <div>
          <h2 className="font-bold text-lg">Ask WeatherGPT</h2>
          <div className="text-sm text-primary-100 flex items-center">
            <span className="w-2 h-2 rounded-full bg-green-400 mr-2 animate-pulse"></span>
            Online (Demo Mode)
          </div>
        </div>
        <div className="flex space-x-2">
          {isSpeaking && (
            <button onClick={stopSpeaking} className="p-2 hover:bg-white/10 rounded-full" title="Stop speaking">
              <X className="w-5 h-5" />
            </button>
          )}
          <button onClick={() => setSpeechMuted(!speechMuted)} className="p-2 hover:bg-white/10 rounded-full" title="Toggle TTS">
            {speechMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Message History */}
      <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-6">
        {messages.map(msg => (
          <div key={msg.id} className={clsx("flex", msg.role === 'user' ? "justify-end" : "justify-start")}>
            <div className={clsx(
              "max-w-[85%] sm:max-w-[75%] rounded-2xl p-4 shadow-sm relative group",
              msg.role === 'user' 
                ? "bg-primary-600 text-white rounded-tr-none" 
                : "bg-slate-50 dark:bg-navy-800 border border-slate-100 dark:border-navy-700 rounded-tl-none"
            )}>
              <p className="leading-relaxed">{msg.content}</p>
              
              {/* Dummy rendering for structured cards */}
              {msg.type === 'alert_card' && (
                <div className="mt-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl p-3 flex items-start space-x-3 text-red-900 dark:text-red-200">
                   <AlertTriangle className="w-5 h-5 flex-shrink-0 text-red-500" />
                   <div className="text-sm font-medium">Severe Rainfall Warning Active</div>
                </div>
              )}
              {msg.type === 'advisory_card' && (
                <div className="mt-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-xl p-3 flex items-start space-x-3 text-green-900 dark:text-green-200">
                   <ShieldAlert className="w-5 h-5 flex-shrink-0 text-green-500" />
                   <div className="text-sm font-medium">Agriculture Advisory: Postpone irrigation</div>
                </div>
              )}
              {msg.type === 'forecast_card' && (
                <div className="mt-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-3 flex items-center space-x-3 text-blue-900 dark:text-blue-200">
                   <CloudRain className="w-8 h-8 flex-shrink-0 text-blue-500" />
                   <div>
                     <div className="text-sm font-bold">Tomorrow</div>
                     <div className="text-xs">32°C • Rain Showers (30%)</div>
                   </div>
                </div>
              )}

              <div className={clsx(
                "text-[10px] mt-2 opacity-0 group-hover:opacity-100 transition-opacity",
                msg.role === 'user' ? "text-primary-100 text-right" : "text-slate-400"
              )}>
                {msg.timestamp}
              </div>
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Composer */}
      <div className="p-4 bg-white dark:bg-navy-900 border-t border-slate-100 dark:border-navy-800 z-10">
        
        {/* Suggestions */}
        <div className="flex overflow-x-auto gap-2 pb-3 mb-1 no-scrollbar">
          {SUGGESTIONS.map((sug, idx) => (
            <button 
              key={idx}
              onClick={() => handleSend(sug)}
              className="whitespace-nowrap text-xs font-medium bg-slate-100 dark:bg-navy-800 hover:bg-slate-200 dark:hover:bg-navy-700 text-slate-700 dark:text-slate-300 px-3 py-1.5 rounded-full transition-colors"
            >
              {sug}
            </button>
          ))}
        </div>

        <form 
          onSubmit={(e) => { e.preventDefault(); handleSend(); }} 
          className="flex items-center space-x-2 bg-slate-50 dark:bg-navy-950 p-1.5 rounded-2xl border border-slate-200 dark:border-navy-700 focus-within:ring-2 focus-within:ring-primary-500/50 transition-all"
        >
          <button 
            type="button"
            onClick={toggleListen}
            className={clsx(
              "p-3 rounded-xl transition-colors shrink-0",
              isListening ? "bg-red-100 text-red-600 animate-pulse" : "hover:bg-slate-200 dark:hover:bg-navy-800 text-slate-500"
            )}
            title={isListening ? "Listening..." : "Tap to speak"}
          >
            {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
          </button>
          
          <input
            type="text"
            value={input}
            onChange={e => setInput(e.target.value)}
            placeholder={isListening ? t('listening') + "..." : "Ask me about the weather..."}
            className="flex-1 bg-transparent border-none outline-none text-slate-800 dark:text-slate-100 placeholder-slate-400 px-2 min-w-0"
          />
          
          <button 
            type="submit"
            disabled={!input.trim()}
            className="bg-primary-600 hover:bg-primary-700 disabled:opacity-50 disabled:hover:bg-primary-600 text-white p-3 rounded-xl transition-colors shrink-0"
          >
            <Send className="w-5 h-5" />
          </button>
        </form>
      </div>
    </div>
  );
}
