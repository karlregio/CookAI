import { useState, useEffect, useRef } from "react";

// ─── Types ───────────────────────────────────────────────────────────────────
type Screen =
  | "splash"
  | "login"
  | "dashboard"
  | "ai-generate"
  | "recipe-overview"
  | "cook-mode"
  | "saved"
  | "history"
  | "profile"
  | "community"
  | "upload"
  | "admin-dashboard"
  | "admin-recipes"
  | "admin-recipe-detail"
  | "user-profile"
  | "conversations"
  | "chat"
  | "notifications"
  | "grocery";

type Tab = "home" | "saved" | "history" | "community" | "profile" | "grocery";

interface RecipeRatingData {
  average: number;
  count: number;
}

interface Recipe {
  id: string;
  title: string;
  cuisine: string;
  time: string;
  difficulty: "Easy" | "Medium" | "Hard";
  image: string;
  servings: number;
  isAIGenerated?: boolean;
  uploader?: string;
  avatarColor?: string;
}

// ─── Data ────────────────────────────────────────────────────────────────────
const OFFICIAL_UPLOADER = "CookAI Official";
const OFFICIAL_AVATAR_COLOR = "#8A9B6E";

const RECIPES: Recipe[] = [
  { id: "1", title: "Spaghetti Pomodoro",   cuisine: "Italian",  time: "25 min", difficulty: "Easy",   servings: 2, uploader: OFFICIAL_UPLOADER, avatarColor: OFFICIAL_AVATAR_COLOR,
    image: "https://images.unsplash.com/photo-1713561058969-793049b01712?w=400&h=300&fit=crop&auto=format" },
  { id: "2", title: "Tonkotsu Ramen",        cuisine: "Japanese", time: "45 min", difficulty: "Medium", servings: 1, uploader: OFFICIAL_UPLOADER, avatarColor: OFFICIAL_AVATAR_COLOR,
    image: "https://images.unsplash.com/photo-1612927601601-6638404737ce?w=400&h=300&fit=crop&auto=format" },
  { id: "3", title: "Street Tacos Al Pastor",cuisine: "Mexican",  time: "35 min", difficulty: "Medium", servings: 4, uploader: OFFICIAL_UPLOADER, avatarColor: OFFICIAL_AVATAR_COLOR,
    image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&h=300&fit=crop&auto=format" },
  { id: "4", title: "Chicken Adobo",         cuisine: "Filipino", time: "50 min", difficulty: "Easy",   servings: 4, uploader: OFFICIAL_UPLOADER, avatarColor: OFFICIAL_AVATAR_COLOR,
    image: "https://images.unsplash.com/photo-1636647511603-f46efb36c327?w=400&h=300&fit=crop&auto=format" },
  { id: "5", title: "Butter Chicken",        cuisine: "Indian",   time: "40 min", difficulty: "Medium", servings: 3, uploader: OFFICIAL_UPLOADER, avatarColor: OFFICIAL_AVATAR_COLOR,
    image: "https://images.unsplash.com/photo-1625631980741-33a7752108f4?w=400&h=300&fit=crop&auto=format" },
  { id: "6", title: "Classic Cheeseburger",  cuisine: "American", time: "20 min", difficulty: "Easy",   servings: 2, uploader: OFFICIAL_UPLOADER, avatarColor: OFFICIAL_AVATAR_COLOR,
    image: "https://images.unsplash.com/photo-1636647511729-6703539ba71f?w=400&h=300&fit=crop&auto=format" },
];

const CATEGORIES = [
  "All",
  "Filipino",
  "Italian",
  "Japanese",
  "Mexican",
  "Indian",
  "American",
  "AI Generate",
];

type StepAction = "boil" | "chop" | "heat" | "saute" | "tomato" | "simmer" | "pasta" | "toss";

const COOK_STEPS: { step: number; text: string; timer: number | null; action: StepAction }[] = [
  {
    step: 1,
    text: "Bring a large pot of salted water to a boil. Use about 1 tablespoon of salt per liter of water.",
    timer: null,
    action: "boil",
  },
  {
    step: 2,
    text: "Finely dice 4 cloves of garlic and 1 small shallot. Set aside in a small bowl.",
    timer: null,
    action: "chop",
  },
  {
    step: 3,
    text: "Heat 3 tablespoons of olive oil in a large skillet over medium heat until shimmering.",
    timer: null,
    action: "heat",
  },
  {
    step: 4,
    text: "Add garlic and shallots to the pan. Sauté until fragrant and golden, stirring occasionally.",
    timer: 180,
    action: "saute",
  },
  {
    step: 5,
    text: "Add a 400g can of San Marzano tomatoes, crushing them by hand as you add them to the pan.",
    timer: null,
    action: "tomato",
  },
  {
    step: 6,
    text: "Season with salt, pepper, and a pinch of sugar. Let the sauce simmer and reduce.",
    timer: 300,
    action: "simmer",
  },
  {
    step: 7,
    text: "Add pasta to boiling water and cook until al dente, 1 minute less than package directions.",
    timer: 480,
    action: "pasta",
  },
  {
    step: 8,
    text: "Reserve ½ cup pasta water, drain pasta, and toss with sauce over high heat. Serve immediately.",
    timer: null,
    action: "toss",
  },
];

const HISTORY_ITEMS = [
  { date: "Today",  recipe: "Tonkotsu Ramen",        uploader: OFFICIAL_UPLOADER, tip: "Used chicken broth substitute — worked great!",
    image: "https://images.unsplash.com/photo-1612927601601-6638404737ce?w=80&h=80&fit=crop&auto=format" },
  { date: "Sep 9",  recipe: "Spaghetti Pomodoro",     uploader: OFFICIAL_UPLOADER, tip: "Added extra garlic per AI suggestion",
    image: "https://images.unsplash.com/photo-1713561058969-793049b01712?w=80&h=80&fit=crop&auto=format" },
  { date: "Sep 7",  recipe: "Chicken Adobo",           uploader: OFFICIAL_UPLOADER, tip: null,
    image: "https://images.unsplash.com/photo-1636647511603-f46efb36c327?w=80&h=80&fit=crop&auto=format" },
  { date: "Sep 4",  recipe: "Street Tacos Al Pastor",  uploader: OFFICIAL_UPLOADER, tip: "Substituted pineapple for mango",
    image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=80&h=80&fit=crop&auto=format" },
];

interface CommunityRecipe extends Recipe {
  uploader: string;
  avatarColor: string;
  likes: number;
  saves: number;
}

const COMMUNITY_RECIPES: CommunityRecipe[] = [
  {
    id: "c1", title: "Miso Glazed Salmon", cuisine: "Japanese", time: "20 min", difficulty: "Easy",
    image: "https://images.unsplash.com/photo-1567529854338-fc097b962123?w=400&h=300&fit=crop&auto=format",
    servings: 2, uploader: "naomi_cooks", avatarColor: "#8A9B6E", likes: 312, saves: 87,
  },
  {
    id: "c2", title: "Lamb Kofta with Tzatziki", cuisine: "Mediterranean", time: "35 min", difficulty: "Medium",
    image: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop&auto=format",
    servings: 4, uploader: "grill_maestro", avatarColor: "#D9713C", likes: 204, saves: 61,
  },
  {
    id: "c3", title: "Pineapple Fried Rice", cuisine: "Thai", time: "25 min", difficulty: "Easy",
    image: "https://images.unsplash.com/photo-1710091691777-3115088962c4?w=400&h=300&fit=crop&auto=format",
    servings: 3, uploader: "bangkok_kitchen", avatarColor: "#B85A28", likes: 178, saves: 44,
  },
  {
    id: "c4", title: "Brown Butter Sage Gnocchi", cuisine: "Italian", time: "40 min", difficulty: "Medium",
    image: "https://images.unsplash.com/photo-1667473775795-41f69ae72c44?w=400&h=300&fit=crop&auto=format",
    servings: 2, uploader: "pasta_perfecta", avatarColor: "#5C4F4A", likes: 431, saves: 129,
  },
  {
    id: "c5", title: "Coconut Dal Tadka", cuisine: "Indian", time: "30 min", difficulty: "Easy",
    image: "https://images.unsplash.com/photo-1627906296851-6d9c5e4db592?w=400&h=300&fit=crop&auto=format",
    servings: 4, uploader: "spice_route", avatarColor: "#8A9B6E", likes: 267, saves: 98,
  },
  {
    id: "c6", title: "Smash Burgers with Special Sauce", cuisine: "American", time: "15 min", difficulty: "Easy",
    image: "https://images.unsplash.com/photo-1636647511729-6703539ba71f?w=400&h=300&fit=crop&auto=format",
    servings: 2, uploader: "weekend_griller", avatarColor: "#D9713C", likes: 589, saves: 201,
  },
];

type AdminStatus = "visible" | "flagged" | "removed";

interface AdminSubmission {
  id: string;
  title: string;
  uploader: string;
  email: string;
  date: string;
  status: AdminStatus;
  flagReasons?: string[];
  image: string;
  cuisine: string;
  servings: number;
  difficulty: "Easy" | "Medium" | "Hard";
  ingredients: string[];
  steps: string[];
}

const ADMIN_SUBMISSIONS: AdminSubmission[] = [
  {
    id: "s1", title: "Miso Glazed Salmon", uploader: "naomi_cooks", email: "naomi@example.com",
    date: "Sep 11, 2026", status: "visible",
    image: "https://images.unsplash.com/photo-1567529854338-fc097b962123?w=400&h=300&fit=crop&auto=format",
    cuisine: "Japanese", servings: 2, difficulty: "Easy",
    ingredients: ["2 salmon fillets (150g each)", "3 tbsp white miso paste", "2 tbsp mirin", "1 tbsp sake", "1 tsp sesame oil", "1 tsp sugar", "Spring onions, to garnish", "Sesame seeds, to garnish"],
    steps: ["Whisk miso, mirin, sake, sesame oil, and sugar into a smooth glaze.", "Pat salmon fillets dry and coat generously with glaze. Marinate 20 min.", "Preheat oven to 200 °C. Line a baking tray with foil.", "Bake salmon 10–12 min until caramelised and just cooked through.", "Garnish with sliced spring onions and sesame seeds. Serve with steamed rice."],
  },
  {
    id: "s2", title: "Lamb Kofta with Tzatziki", uploader: "grill_maestro", email: "grillmaestro@example.com",
    date: "Sep 10, 2026", status: "visible",
    image: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop&auto=format",
    cuisine: "Mediterranean", servings: 4, difficulty: "Medium",
    ingredients: ["500g ground lamb", "1 onion, grated", "3 cloves garlic, minced", "2 tsp cumin", "1 tsp coriander", "½ tsp cinnamon", "Salt and black pepper", "Fresh parsley, chopped", "For tzatziki: Greek yogurt, cucumber, dill, lemon"],
    steps: ["Combine lamb, onion, garlic, spices, and parsley. Mix well.", "Shape into 8 oval koftas around metal skewers.", "Grill over high heat 3–4 min per side until charred and cooked.", "Meanwhile, make tzatziki: grate cucumber, squeeze dry, mix with yogurt, dill, lemon.", "Serve koftas with tzatziki, warm flatbread, and sliced tomatoes."],
  },
  {
    id: "s3", title: "Pineapple Fried Rice", uploader: "bangkok_kitchen", email: "bkkitchen@example.com",
    date: "Sep 10, 2026", status: "flagged",
    flagReasons: ["Ingredient quantities appear inconsistent (2 cups rice, serves 8 listed as 2)", "Unverified health claim: 'boosts metabolism' in description"],
    image: "https://images.unsplash.com/photo-1710091691777-3115088962c4?w=400&h=300&fit=crop&auto=format",
    cuisine: "Thai", servings: 2, difficulty: "Easy",
    ingredients: ["2 cups cooked jasmine rice (day-old)", "1 small pineapple, diced", "2 eggs", "100g prawns, peeled", "3 tbsp fish sauce", "1 tbsp soy sauce", "2 tsp sugar", "Spring onions, cashews, to garnish"],
    steps: ["Heat wok over high heat until smoking. Add oil.", "Scramble eggs briefly, then push to side.", "Add prawns and cook 2 min. Add rice and stir-fry 3 min.", "Add pineapple, fish sauce, soy sauce, sugar. Toss well.", "Serve garnished with cashews and spring onions."],
  },
  {
    id: "s4", title: "Brown Butter Sage Gnocchi", uploader: "pasta_perfecta", email: "pastaperfecta@example.com",
    date: "Sep 9, 2026", status: "visible",
    image: "https://images.unsplash.com/photo-1667473775795-41f69ae72c44?w=400&h=300&fit=crop&auto=format",
    cuisine: "Italian", servings: 2, difficulty: "Medium",
    ingredients: ["500g store-bought potato gnocchi", "80g unsalted butter", "12 fresh sage leaves", "2 cloves garlic, halved", "Salt and black pepper", "Parmesan, freshly grated", "Lemon zest, to finish"],
    steps: ["Cook gnocchi in boiling salted water until they float (2–3 min). Drain.", "Melt butter in a wide pan over medium heat. Add garlic and sage.", "Cook until butter turns golden and smells nutty — watch closely.", "Remove garlic. Add drained gnocchi and toss to coat.", "Plate immediately, top with Parmesan and lemon zest."],
  },
  {
    id: "s5", title: "Coconut Dal Tadka", uploader: "spice_route", email: "spiceroute@example.com",
    date: "Sep 8, 2026", status: "visible",
    image: "https://images.unsplash.com/photo-1627906296851-6d9c5e4db592?w=400&h=300&fit=crop&auto=format",
    cuisine: "Indian", servings: 4, difficulty: "Easy",
    ingredients: ["200g red lentils, rinsed", "400ml coconut milk", "1 onion, diced", "3 cloves garlic", "1 tsp ginger, grated", "1 tsp turmeric", "1 tsp cumin seeds", "1 tsp garam masala", "Fresh coriander, to garnish"],
    steps: ["Simmer lentils with turmeric and 600ml water until soft, ~20 min.", "Stir in coconut milk and simmer 5 more min.", "For tadka: heat oil, fry cumin seeds, onion, garlic, ginger until golden.", "Add garam masala to tadka, cook 1 min, then pour over dal.", "Serve with rice or naan and fresh coriander."],
  },
  {
    id: "s6", title: "Smash Burgers", uploader: "weekend_griller", email: "weekendgriller@example.com",
    date: "Sep 7, 2026", status: "flagged",
    flagReasons: ["Photo appears to be stock imagery, not original cook", "Recipe duplicates an existing submission (s2 from weekend_griller)"],
    image: "https://images.unsplash.com/photo-1636647511729-6703539ba71f?w=400&h=300&fit=crop&auto=format",
    cuisine: "American", servings: 2, difficulty: "Easy",
    ingredients: ["300g 80/20 ground beef", "4 slices American cheese", "2 brioche buns, toasted", "Special sauce: mayo, ketchup, mustard, pickles, onion powder"],
    steps: ["Divide beef into 2 loose balls. Season generously.", "Heat cast-iron over high heat until smoking. Place balls, immediately smash flat.", "Cook 2 min, flip, add cheese, cook 1 more min.", "Mix special sauce ingredients. Spread on toasted buns.", "Assemble with lettuce, tomato, pickles. Serve immediately."],
  },
  {
    id: "s7", title: "Korean Japchae", uploader: "seoul_eats", email: "seouleats@example.com",
    date: "Sep 7, 2026", status: "visible",
    image: "https://images.unsplash.com/photo-1612927601601-6638404737ce?w=400&h=300&fit=crop&auto=format",
    cuisine: "Korean", servings: 3, difficulty: "Medium",
    ingredients: ["200g glass noodles (dangmyeon)", "150g beef sirloin, julienned", "1 carrot, julienned", "1 onion, sliced", "3 tbsp soy sauce", "2 tbsp sesame oil", "1 tbsp sugar", "Spinach, mushrooms, egg"],
    steps: ["Soak noodles in cold water 30 min. Boil 6 min, rinse, drain.", "Marinate beef in soy sauce, sesame oil, sugar. Stir-fry 3 min.", "Sauté vegetables separately until just tender.", "Combine noodles, beef, vegetables with remaining sauce.", "Toss over heat 2 min. Garnish with sesame seeds and sliced egg."],
  },
  {
    id: "s8", title: "Shakshuka Deluxe", uploader: "brunch_boss", email: "brunchboss@example.com",
    date: "Sep 6, 2026", status: "visible",
    image: "https://images.unsplash.com/photo-1625631980741-33a7752108f4?w=400&h=300&fit=crop&auto=format",
    cuisine: "Middle Eastern", servings: 3, difficulty: "Easy",
    ingredients: ["6 eggs", "2 cans crushed tomatoes (800g)", "1 red pepper, diced", "1 onion, diced", "4 cloves garlic", "2 tsp cumin", "1 tsp smoked paprika", "½ tsp chilli flakes", "Feta, fresh parsley, crusty bread to serve"],
    steps: ["Sauté onion and pepper in olive oil over medium heat until soft.", "Add garlic and spices. Cook 1 min until fragrant.", "Pour in tomatoes, season, simmer 10 min to thicken.", "Make wells in sauce, crack in eggs. Cover, cook 6–8 min.", "Top with crumbled feta, parsley, and a drizzle of olive oil."],
  },
];

interface CommunityUser {
  uploader: string;
  avatarColor: string;
  bio: string;
  recipesCount: number;
  totalLikes: number;
}

const COMMUNITY_USERS: Record<string, CommunityUser> = {
  naomi_cooks:    { uploader: "naomi_cooks",    avatarColor: "#8A9B6E", bio: "Home cook obsessed with Japanese flavours & seasonal produce. Tokyo → London.", recipesCount: 14, totalLikes: 1840 },
  grill_maestro:  { uploader: "grill_maestro",  avatarColor: "#D9713C", bio: "Outdoor grilling enthusiast. If it doesn't have char marks, did you even cook it?", recipesCount: 9,  totalLikes: 963 },
  bangkok_kitchen:{ uploader: "bangkok_kitchen",avatarColor: "#B85A28", bio: "Bringing street-food energy to your home kitchen. 🌶 Always spicy.", recipesCount: 22, totalLikes: 2310 },
  pasta_perfecta: { uploader: "pasta_perfecta", avatarColor: "#5C4F4A", bio: "Nonnas of Italy, I salute you. Pasta every day, twice on Sundays.", recipesCount: 31, totalLikes: 5120 },
  spice_route:    { uploader: "spice_route",    avatarColor: "#8A9B6E", bio: "Tracing the ancient spice routes one dish at a time. Vegetarian-friendly.", recipesCount: 18, totalLikes: 2670 },
  weekend_griller:{ uploader: "weekend_griller",avatarColor: "#D9713C", bio: "Burgers, BBQ, and backyard vibes. Weekend warrior chef.", recipesCount: 7,  totalLikes: 1200 },
};

interface Conversation {
  id: string;
  uploader: string;
  avatarColor: string;
  lastMessage: string;
  timestamp: string;
  unread: number;
}

const CONVERSATIONS: Conversation[] = [
  { id: "cv1", uploader: "naomi_cooks",    avatarColor: "#8A9B6E", lastMessage: "Thanks! The miso glaze trick really works.", timestamp: "2m ago",   unread: 2 },
  { id: "cv2", uploader: "pasta_perfecta", avatarColor: "#5C4F4A", lastMessage: "You should try it with fresh tagliatelle.", timestamp: "1h ago",   unread: 0 },
  { id: "cv3", uploader: "bangkok_kitchen",avatarColor: "#B85A28", lastMessage: "Let me know how the chilli substitution went!", timestamp: "Yesterday", unread: 1 },
  { id: "cv4", uploader: "grill_maestro",  avatarColor: "#D9713C", lastMessage: "I'll send you the marinade recipe 🔥",       timestamp: "2d ago",   unread: 0 },
];

interface ChatMessage {
  id: string;
  role: "me" | "them";
  text: string;
  time: string;
}

const CHAT_HISTORY: Record<string, ChatMessage[]> = {
  naomi_cooks: [
    { id: "1", role: "them", text: "Hey! Loved your comment on the ramen recipe 🍜", time: "10:04 AM" },
    { id: "2", role: "me",   text: "Thanks! That broth technique is genius. How long do you simmer the bones for?", time: "10:06 AM" },
    { id: "3", role: "them", text: "At least 6 hours for a rich result — overnight if you can manage it!", time: "10:08 AM" },
    { id: "4", role: "me",   text: "Wow okay, worth it. Does it freeze well?", time: "10:09 AM" },
    { id: "5", role: "them", text: "Thanks! The miso glaze trick really works.", time: "10:11 AM" },
  ],
  pasta_perfecta: [
    { id: "1", role: "them", text: "Ciao! Saw you saved the gnocchi recipe — let me know if you need tips!", time: "Yesterday" },
    { id: "2", role: "me",   text: "Would love that. I always end up with rubbery gnocchi 😅", time: "Yesterday" },
    { id: "3", role: "them", text: "The trick is to work the dough as little as possible. Barely mix.", time: "Yesterday" },
    { id: "4", role: "them", text: "You should try it with fresh tagliatelle.", time: "Yesterday" },
  ],
  bangkok_kitchen: [
    { id: "1", role: "me",   text: "Hey! Can I substitute bird's eye chilli for regular red chilli?", time: "Tue" },
    { id: "2", role: "them", text: "Yes but use double the amount — bird's eye is much hotter per gram.", time: "Tue" },
    { id: "3", role: "them", text: "Let me know how the chilli substitution went!", time: "Tue" },
  ],
  grill_maestro: [
    { id: "1", role: "them", text: "Nice BBQ setup you've got! What grill do you use?", time: "Mon" },
    { id: "2", role: "me",   text: "Just a basic Weber kettle — works great for most things.", time: "Mon" },
    { id: "3", role: "them", text: "I'll send you the marinade recipe 🔥", time: "Mon" },
  ],
};

const AI_MESSAGES = [
  {
    role: "user" as const,
    text: "What can I substitute for heavy cream in this sauce?",
  },
  {
    role: "ai" as const,
    text: "Great question! For this tomato sauce, try half-and-half, evaporated milk, or full-fat coconut milk for a richer flavor. If you want to keep it lighter, a splash of pasta water whisked with a bit of butter works beautifully.",
  },
];

// ─── Seed ratings (recipeId → { average, count }) ────────────────────────────
const SEED_RATINGS: Record<string, RecipeRatingData> = {
  "1":  { average: 4.7, count: 214 },
  "2":  { average: 4.4, count: 98  },
  "3":  { average: 4.2, count: 76  },
  "4":  { average: 4.8, count: 183 },
  "5":  { average: 4.5, count: 127 },
  "6":  { average: 4.1, count: 61  },
  "c1": { average: 4.6, count: 89  },
  "c2": { average: 4.3, count: 54  },
  "c3": { average: 4.0, count: 32  },
  "c4": { average: 4.9, count: 71  },
  "c5": { average: 4.2, count: 48  },
  "c6": { average: 4.7, count: 203 },
};

// ─── AI Variation pool ───────────────────────────────────────────────────────
// Cycled through on each "Regenerate with AI" tap so every press produces
// a meaningfully different recipe rather than re-rendering the same content.
const AI_VARIATIONS: Recipe[] = [
  { id: "ai-v1", title: "Spiced Coconut Butter Chicken", cuisine: "Indian", time: "40 min", difficulty: "Medium", servings: 4, isAIGenerated: true,
    image: "https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=800&q=80" },
  { id: "ai-v2", title: "Smoky Harissa Chicken Tray Bake", cuisine: "North African", time: "50 min", difficulty: "Easy", servings: 4, isAIGenerated: true,
    image: "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800&q=80" },
  { id: "ai-v3", title: "Lemon-Herb Roast Chicken & Roots", cuisine: "French", time: "1 hr 10 min", difficulty: "Medium", servings: 4, isAIGenerated: true,
    image: "https://images.unsplash.com/photo-1518492104633-130d0cc84637?w=800&q=80" },
  { id: "ai-v4", title: "Tandoori-Style Chicken Skewers", cuisine: "Indian", time: "30 min", difficulty: "Easy", servings: 3, isAIGenerated: true,
    image: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=800&q=80" },
  { id: "ai-v5", title: "Miso-Glazed Chicken Thighs", cuisine: "Japanese", time: "35 min", difficulty: "Easy", servings: 2, isAIGenerated: true,
    image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80" },
];

// ─── Grocery list ────────────────────────────────────────────────────────────

interface GroceryItem {
  id: string;
  name: string;
  recipeTitle: string;
  category: string;
  checked: boolean;
}

// Heuristic category tagger — keeps the screen feeling smart without backend
function tagCategory(ingredient: string): string {
  const s = ingredient.toLowerCase();
  if (/tomato|basil|garlic|shallot|onion|lemon|lime|ginger|chili|pepper|mushroom|spinach|arugula|scallion|parsley|coriander|mint|papaya|pineapple|mango|apple|avocado/.test(s)) return "Produce";
  if (/pasta|spaghetti|rice|flour|panko|bread|cracker|ramen|noodle|gnocchi/.test(s)) return "Pantry";
  if (/oil|butter|sugar|salt|vinegar|soy sauce|miso|fish sauce|oyster|sesame|honey|stock|broth|coconut milk|tahini/.test(s)) return "Pantry";
  if (/parmesan|cheese|cream|milk|yogurt|egg/.test(s)) return "Dairy & Eggs";
  if (/chicken|beef|pork|salmon|shrimp|lamb|sausage|bacon|pancetta/.test(s)) return "Meat & Fish";
  return "Other";
}

// ─── Notifications ────────────────────────────────────────────────────────────

interface Notification {
  id: string;
  type: "cooked" | "liked" | "commented" | "saved" | "flagged" | "removed";
  fromUser: string;
  avatarColor: string;
  recipeName: string;
  recipeId: string;
  timestamp: string;
  read: boolean;
  adminReason?: string;
}

const SEED_NOTIFICATIONS: Notification[] = [
  { id: "n1", type: "cooked", fromUser: "naomi_cooks", avatarColor: "#8A9B6E", recipeName: "Spaghetti Pomodoro", recipeId: "r1", timestamp: "2m ago", read: false },
  { id: "n2", type: "liked", fromUser: "chef_marco", avatarColor: "#D9713C", recipeName: "Spaghetti Pomodoro", recipeId: "r1", timestamp: "14m ago", read: false },
  { id: "n3", type: "commented", fromUser: "yuki_eats", avatarColor: "#9C8F8A", recipeName: "Miso Ramen", recipeId: "r3", timestamp: "1h ago", read: false },
  { id: "n4", type: "cooked", fromUser: "amara_kitchen", avatarColor: "#B3C49A", recipeName: "Spaghetti Pomodoro", recipeId: "r1", timestamp: "3h ago", read: true },
  { id: "n5", type: "saved", fromUser: "phoebe_bakes", avatarColor: "#D9713C", recipeName: "Miso Ramen", recipeId: "r3", timestamp: "5h ago", read: true },
  { id: "n6", type: "liked", fromUser: "naomi_cooks", avatarColor: "#8A9B6E", recipeName: "Green Papaya Salad", recipeId: "r5", timestamp: "Yesterday", read: true },
];

// ─── Star rating components ───────────────────────────────────────────────────

const STAR_COLOR = "#C8920A"; // amber/gold — distinct from terracotta heart

// Single star SVG with precise partial fill via clipPath
function StarIcon({ fill = 1, size = 14 }: { fill?: number; size?: number }) {
  const id = `sf-${Math.round(fill * 100)}-${size}`;
  return (
    <svg width={size} height={size} viewBox="0 0 20 20" fill="none">
      <defs>
        <clipPath id={id}>
          <rect x="0" y="0" width={20 * Math.max(0, Math.min(1, fill))} height="20" />
        </clipPath>
      </defs>
      {/* Outline star */}
      <path
        d="M10 1.5l2.47 5.01 5.53.8-4 3.9.94 5.5L10 14.1l-4.94 2.6.94-5.5-4-3.9 5.53-.8L10 1.5z"
        stroke={STAR_COLOR}
        strokeWidth="1.4"
        fill="none"
        opacity={0.35}
      />
      {/* Filled portion */}
      <path
        d="M10 1.5l2.47 5.01 5.53.8-4 3.9.94 5.5L10 14.1l-4.94 2.6.94-5.5-4-3.9 5.53-.8L10 1.5z"
        fill={STAR_COLOR}
        clipPath={`url(#${id})`}
      />
    </svg>
  );
}

// Read-only star row: fills each of 5 stars proportionally
function StarRating({
  average,
  count,
  size = 14,
  showCount = true,
}: {
  average: number;
  count?: number;
  size?: number;
  showCount?: boolean;
}) {
  return (
    <div className="flex items-center gap-1">
      <div className="flex items-center gap-0.5">
        {[1, 2, 3, 4, 5].map((n) => (
          <StarIcon key={n} fill={Math.min(1, Math.max(0, average - (n - 1)))} size={size} />
        ))}
      </div>
      <span
        className="font-semibold leading-none"
        style={{ fontFamily: "Outfit, sans-serif", color: STAR_COLOR, fontSize: size - 1 }}
      >
        {average.toFixed(1)}
      </span>
      {showCount && count !== undefined && (
        <span
          className="text-[#C4B8B3] leading-none"
          style={{ fontFamily: "Outfit, sans-serif", fontSize: size - 3 }}
        >
          ({count.toLocaleString()})
        </span>
      )}
    </div>
  );
}

// Interactive 5-star picker — tap to set rating, tap same star to clear
function StarPicker({
  value,
  onChange,
  size = 32,
}: {
  value: number;
  onChange: (v: number) => void;
  size?: number;
}) {
  const [hovered, setHovered] = useState(0);
  const display = hovered || value;
  return (
    <div className="flex items-center gap-2">
      {[1, 2, 3, 4, 5].map((n) => (
        <button
          key={n}
          onMouseEnter={() => setHovered(n)}
          onMouseLeave={() => setHovered(0)}
          onClick={() => onChange(value === n ? 0 : n)}
          className="active:scale-110 transition-transform"
        >
          <StarIcon fill={n <= display ? 1 : 0} size={size} />
        </button>
      ))}
    </div>
  );
}

// ─── Shared Components ────────────────────────────────────────────────────────

function DifficultyBadge({ level }: { level: string }) {
  const colors: Record<string, string> = {
    Easy: "bg-[#8A9B6E]/15 text-[#8A9B6E]",
    Medium: "bg-[#D9713C]/15 text-[#D9713C]",
    Hard: "bg-[#2B2420]/10 text-[#5C4F4A]",
  };
  return (
    <span
      className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${colors[level] || colors.Easy}`}
      style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.04em" }}
    >
      {level}
    </span>
  );
}

// Shared attribution row used on cards AND recipe detail screens.
// size="sm" → compact card row; size="md" → detail-screen row
function UploaderAttribution({
  uploader,
  avatarColor,
  size = "sm",
}: {
  uploader: string;
  avatarColor?: string;
  size?: "sm" | "md";
}) {
  const isOfficial = uploader === OFFICIAL_UPLOADER;
  const color = avatarColor ?? (isOfficial ? OFFICIAL_AVATAR_COLOR : "#9C8F8A");
  const avatarSize = size === "sm" ? "w-4 h-4" : "w-7 h-7";
  const fontSize = size === "sm" ? "text-[10px]" : "text-[13px]";
  const initial = isOfficial ? "✦" : uploader[0].toUpperCase();

  return (
    <div className={`flex items-center gap-1.5 ${size === "md" ? "py-2.5 px-3 bg-[rgba(43,36,32,0.035)] rounded-2xl" : ""}`}>
      {/* Avatar */}
      <div
        className={`${avatarSize} rounded-full flex items-center justify-center flex-shrink-0 text-white`}
        style={{
          background: isOfficial
            ? `linear-gradient(135deg, ${color} 0%, #B3C49A 100%)`
            : color,
          fontSize: size === "sm" ? 6 : 10,
          fontFamily: "Lora, serif",
          fontWeight: 700,
        }}
      >
        {isOfficial ? (
          // CookAI spark mark
          <svg width={size === "sm" ? 7 : 12} height={size === "sm" ? 7 : 12} viewBox="0 0 12 12" fill="none">
            <path d="M6 1l1.2 3.8H11L8.1 6.9l1.2 3.8L6 8.6l-3.3 2.1 1.2-3.8L1 4.8h3.8L6 1z" fill="white" />
          </svg>
        ) : (
          <span style={{ lineHeight: 1 }}>{initial}</span>
        )}
      </div>

      {/* Name */}
      <span
        className={`${fontSize} font-semibold leading-none`}
        style={{
          fontFamily: "Outfit, sans-serif",
          color: isOfficial ? color : "#9C8F8A",
        }}
      >
        {isOfficial ? "CookAI Official" : `@${uploader}`}
      </span>

      {/* Verified badge */}
      {isOfficial ? (
        // Filled checkmark circle — sage green for official
        <svg width={size === "sm" ? 10 : 14} height={size === "sm" ? 10 : 14} viewBox="0 0 16 16" fill="none">
          <circle cx="8" cy="8" r="8" fill={color} />
          <path d="M4.5 8l2.5 2.5 4.5-4.5" stroke="white" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      ) : (
        // Subtle outline checkmark for regular community users
        <svg width={size === "sm" ? 9 : 12} height={size === "sm" ? 9 : 12} viewBox="0 0 16 16" fill="none">
          <circle cx="8" cy="8" r="7" stroke="#C4B8B3" strokeWidth="1.5" />
          <path d="M5 8l2 2 4-4" stroke="#C4B8B3" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      )}
    </div>
  );
}

function RecipeCard({
  recipe,
  rating,
  onTap,
}: {
  recipe: Recipe;
  rating?: RecipeRatingData;
  onTap: () => void;
}) {
  return (
    <button
      onClick={onTap}
      className="w-full text-left bg-white rounded-[20px] overflow-hidden shadow-[0_2px_16px_rgba(43,36,32,0.08)] active:scale-[0.98] transition-transform"
    >
      <div className="relative bg-[#E8DDD5]" style={{ paddingTop: "66.7%" }}>
        <img
          src={recipe.image}
          alt={recipe.title}
          className="absolute inset-0 w-full h-full object-cover"
        />
        {/* Compact star badge overlaid on image bottom-left */}
        {rating && (
          <div className="absolute bottom-2 left-2 flex items-center gap-1 px-2 py-0.5 rounded-full" style={{ background: "rgba(0,0,0,0.45)", backdropFilter: "blur(4px)" }}>
            <StarIcon fill={1} size={10} />
            <span className="text-white text-[11px] font-semibold leading-none" style={{ fontFamily: "Outfit, sans-serif" }}>{rating.average.toFixed(1)}</span>
          </div>
        )}
      </div>
      <div className="p-3 pb-3.5">
        <h3
          className="text-[#2B2420] font-semibold text-sm leading-snug mb-1.5"
          style={{ fontFamily: "Lora, serif" }}
        >
          {recipe.title}
        </h3>
        {recipe.uploader && (
          <div className="mb-1.5">
            <UploaderAttribution uploader={recipe.uploader} avatarColor={recipe.avatarColor} size="sm" />
          </div>
        )}
        <div className="flex items-center justify-between">
          <span
            className="text-[#9C8F8A] text-[11px]"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            ⏱ {recipe.time}
          </span>
          <DifficultyBadge level={recipe.difficulty} />
        </div>
      </div>
    </button>
  );
}

// ─── Bottom Tab Bar ───────────────────────────────────────────────────────────

function TabBar({
  active,
  onSelect,
}: {
  active: Tab;
  onSelect: (t: Tab) => void;
}) {
  const tabs: { id: Tab; label: string; icon: string }[] = [
    { id: "home",    label: "Home",    icon: "home" },
    { id: "saved",   label: "Saved",   icon: "bookmark" },
    { id: "grocery", label: "Grocery", icon: "cart" },
    { id: "history", label: "History", icon: "clock" },
    { id: "profile", label: "Profile", icon: "user" },
  ];

  return (
    <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-[rgba(43,36,32,0.08)] flex">
      {tabs.map((t) => (
        <button
          key={t.id}
          onClick={() => onSelect(t.id)}
          className="flex-1 flex flex-col items-center pt-3 pb-6 gap-1 active:opacity-70 transition-opacity"
        >
          <TabIcon name={t.icon} active={active === t.id} />
          <span
            className={`text-[10px] font-medium ${active === t.id ? "text-[#D9713C]" : "text-[#9C8F8A]"}`}
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            {t.label}
          </span>
        </button>
      ))}
    </div>
  );
}

function TabIcon({ name, active }: { name: string; active: boolean }) {
  const color = active ? "#D9713C" : "#9C8F8A";
  const size = 22;
  if (name === "home")
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <path
          d="M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1H4a1 1 0 01-1-1V9.5z"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          fill={active ? `${color}20` : "none"}
          strokeLinejoin="round"
        />
        <path
          d="M9 21V12h6v9"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          strokeLinejoin="round"
        />
      </svg>
    );
  if (name === "bookmark")
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <path
          d="M5 3h14a1 1 0 011 1v17l-8-4-8 4V4a1 1 0 011-1z"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          fill={active ? `${color}20` : "none"}
          strokeLinejoin="round"
        />
      </svg>
    );
  if (name === "community")
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <circle cx="9" cy="7" r="3" stroke={color} strokeWidth={active ? 2 : 1.75} fill={active ? `${color}20` : "none"} />
        <circle cx="17" cy="9" r="2.5" stroke={color} strokeWidth={active ? 2 : 1.75} fill={active ? `${color}15` : "none"} />
        <path d="M2 20c0-3.3 3.1-6 7-6s7 2.7 7 6" stroke={color} strokeWidth={active ? 2 : 1.75} strokeLinecap="round" />
        <path d="M17 14c2.2 0 4 1.6 4 4" stroke={color} strokeWidth={active ? 2 : 1.75} strokeLinecap="round" />
      </svg>
    );
  if (name === "clock")
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <circle
          cx="12"
          cy="12"
          r="9"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          fill={active ? `${color}15` : "none"}
        />
        <path
          d="M12 7v5l3 3"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          strokeLinecap="round"
        />
      </svg>
    );
  if (name === "cart")
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke={color} strokeWidth={active ? 2 : 1.75} fill={active ? `${color}18` : "none"} strokeLinejoin="round" />
        <path d="M3 6h18" stroke={color} strokeWidth={active ? 2 : 1.75} strokeLinecap="round" />
        <path d="M16 10a4 4 0 01-8 0" stroke={color} strokeWidth={active ? 2 : 1.75} strokeLinecap="round" />
      </svg>
    );
  if (name === "user")
    return (
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
        <circle
          cx="12"
          cy="8"
          r="4"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          fill={active ? `${color}20` : "none"}
        />
        <path
          d="M4 20c0-4 3.6-7 8-7s8 3 8 7"
          stroke={color}
          strokeWidth={active ? 2 : 1.75}
          strokeLinecap="round"
        />
      </svg>
    );
  return null;
}

// ─── Fullscreen Image Viewer ──────────────────────────────────────────────────

function FullscreenImageViewer({ src, alt, onClose }: { src: string; alt: string; onClose: () => void }) {
  const [scale, setScale] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const lastTap = useRef(0);
  const lastDist = useRef<number | null>(null);
  const dragStart = useRef<{ x: number; y: number; ox: number; oy: number } | null>(null);

  const clampOffset = (s: number, ox: number, oy: number) => {
    const maxX = Math.max(0, ((s - 1) * 390) / 2);
    const maxY = Math.max(0, ((s - 1) * 844) / 2);
    return { x: Math.min(maxX, Math.max(-maxX, ox)), y: Math.min(maxY, Math.max(-maxY, oy)) };
  };

  const handleDoubleTap = (e: React.TouchEvent) => {
    const now = Date.now();
    if (now - lastTap.current < 300) {
      const next = scale > 1 ? 1 : 2.5;
      setScale(next);
      setOffset(next === 1 ? { x: 0, y: 0 } : clampOffset(next, 0, 0));
    }
    lastTap.current = now;
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      dragStart.current = { x: e.touches[0].clientX, y: e.touches[0].clientY, ox: offset.x, oy: offset.y };
    }
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (e.touches.length === 2) {
      const dx = e.touches[0].clientX - e.touches[1].clientX;
      const dy = e.touches[0].clientY - e.touches[1].clientY;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (lastDist.current !== null) {
        const delta = dist - lastDist.current;
        setScale((prev) => {
          const next = Math.min(5, Math.max(1, prev + delta * 0.012));
          setOffset((o) => clampOffset(next, o.x, o.y));
          return next;
        });
      }
      lastDist.current = dist;
      dragStart.current = null;
    } else if (e.touches.length === 1 && dragStart.current && scale > 1) {
      const dx = e.touches[0].clientX - dragStart.current.x;
      const dy = e.touches[0].clientY - dragStart.current.y;
      setOffset(clampOffset(scale, dragStart.current.ox + dx, dragStart.current.oy + dy));
    }
  };

  const handleTouchEnd = () => { lastDist.current = null; };

  return (
    <div className="absolute inset-0 z-50 bg-black flex items-center justify-center overflow-hidden">
      {/* Close button */}
      <button
        onClick={onClose}
        className="absolute top-12 left-4 z-10 w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center"
        style={{ border: "1px solid rgba(255,255,255,0.3)" }}
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path d="M18 6L6 18M6 6l12 12" stroke="white" strokeWidth="2.2" strokeLinecap="round" />
        </svg>
      </button>

      {/* Pinch-to-zoom hint */}
      {scale === 1 && (
        <div className="absolute bottom-16 left-0 right-0 flex justify-center pointer-events-none">
          <span className="text-white/50 text-[12px]" style={{ fontFamily: "Outfit, sans-serif" }}>Pinch or double-tap to zoom</span>
        </div>
      )}

      {/* Zoom indicator */}
      {scale > 1 && (
        <div className="absolute bottom-16 left-0 right-0 flex justify-center pointer-events-none">
          <span className="text-white/50 text-[12px]" style={{ fontFamily: "Outfit, sans-serif" }}>{scale.toFixed(1)}×</span>
        </div>
      )}

      <div
        className="absolute inset-0 flex items-center justify-center"
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
        onClick={(e) => { if (scale === 1 && e.target === e.currentTarget) onClose(); }}
      >
        <img
          src={src}
          alt={alt}
          onDoubleClick={() => {}}
          onTouchStart={handleDoubleTap}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "contain",
            transform: `scale(${scale}) translate(${offset.x / scale}px, ${offset.y / scale}px)`,
            transition: scale === 1 ? "transform 0.3s ease" : "none",
            userSelect: "none",
            WebkitUserSelect: "none",
            touchAction: "none",
          }}
          draggable={false}
        />
      </div>
    </div>
  );
}

// ─── Screen: Dashboard ────────────────────────────────────────────────────────

function DashboardScreen({
  onRecipe,
  onGenerate,
  activeTab,
  onTab,
  onMessages,
  onNotifications,
  unreadNotifications,
  ratings,
}: {
  onRecipe: (r: Recipe) => void;
  onGenerate: () => void;
  activeTab: Tab;
  onTab: (t: Tab) => void;
  onMessages: () => void;
  onNotifications: () => void;
  unreadNotifications: number;
  ratings: Record<string, RecipeRatingData>;
}) {
  const [activeCategory, setActiveCategory] = useState("All");
  const [search, setSearch] = useState("");

  const filtered =
    activeCategory === "All"
      ? RECIPES
      : RECIPES.filter((r) => r.cuisine === activeCategory);
  const searched = search
    ? filtered.filter((r) =>
        r.title.toLowerCase().includes(search.toLowerCase()),
      )
    : filtered;

  return (
    <div className="absolute inset-0 flex flex-col bg-[#FDF8F3]">
      {/* Header */}
      <div className="pt-14 px-5 pb-4">
        <div className="flex items-center justify-between mb-1">
          <span
            className="text-[#9C8F8A] text-sm"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            Good morning, Alex 👋
          </span>
          <div className="flex items-center gap-2">
            {/* Bell / Notifications */}
            <button
              onClick={onNotifications}
              className="relative w-9 h-9 rounded-full bg-white border border-[rgba(43,36,32,0.08)] flex items-center justify-center shadow-[0_1px_6px_rgba(43,36,32,0.07)] active:opacity-70 transition-opacity"
            >
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none">
                <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0" stroke="#5C4F4A" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              {unreadNotifications > 0 && (
                <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#D9713C] text-white text-[9px] font-bold flex items-center justify-center" style={{ fontFamily: "Outfit, sans-serif" }}>{unreadNotifications > 9 ? "9+" : unreadNotifications}</span>
              )}
            </button>
            {/* Messages icon */}
            <button
              onClick={onMessages}
              className="relative w-9 h-9 rounded-full bg-white border border-[rgba(43,36,32,0.08)] flex items-center justify-center shadow-[0_1px_6px_rgba(43,36,32,0.07)] active:opacity-70 transition-opacity"
            >
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none">
                <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" stroke="#5C4F4A" strokeWidth="1.75" strokeLinejoin="round" />
              </svg>
              <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#D9713C] text-white text-[9px] font-bold flex items-center justify-center" style={{ fontFamily: "Outfit, sans-serif" }}>3</span>
            </button>
            <div className="w-9 h-9 rounded-full bg-[#D9713C]/20 flex items-center justify-center">
              <span className="text-sm font-semibold text-[#D9713C]">A</span>
            </div>
          </div>
        </div>
        <h1
          className="text-[#2B2420] text-2xl leading-tight"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          What are we cooking
          <br />
          today?
        </h1>

        {/* Search */}
        <div className="mt-4 relative">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <circle cx="11" cy="11" r="7" stroke="#9C8F8A" strokeWidth="2" />
              <path
                d="M16.5 16.5L21 21"
                stroke="#9C8F8A"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </svg>
          </div>
          <input
            type="text"
            placeholder="Search recipes..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white rounded-full pl-10 pr-4 py-3 text-sm text-[#2B2420] placeholder-[#C4B8B3] shadow-[0_1px_8px_rgba(43,36,32,0.07)] outline-none border border-[rgba(43,36,32,0.06)]"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
        </div>
      </div>

      {/* Category Chips */}
      <div className="px-5 mb-4">
        <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
          {CATEGORIES.map((cat) => {
            const isAI = cat === "AI Generate";
            const isActive = activeCategory === cat;
            return (
              <button
                key={cat}
                onClick={() => {
                  if (isAI) {
                    onGenerate();
                  } else {
                    setActiveCategory(cat);
                  }
                }}
                className={`flex-shrink-0 flex items-center gap-1.5 px-4 py-2 rounded-full text-[13px] font-medium transition-all ${
                  isAI
                    ? "bg-[#2B2420] text-white"
                    : isActive
                      ? "bg-[#D9713C] text-white shadow-[0_2px_8px_rgba(217,113,60,0.3)]"
                      : "bg-white text-[#5C4F4A] border border-[rgba(43,36,32,0.1)]"
                }`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {isAI && <span className="text-[12px]">✦</span>}
                {cat}
              </button>
            );
          })}
        </div>
      </div>

      {/* Recipe Grid */}
      <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-24">
        <div className="grid grid-cols-2 gap-3">
          {searched.map((recipe) => (
            <RecipeCard
              key={recipe.id}
              recipe={recipe}
              rating={ratings[recipe.id]}
              onTap={() => onRecipe(recipe)}
            />
          ))}
        </div>
        {searched.length === 0 && (
          <div className="text-center py-16 text-[#9C8F8A]">
            <div className="text-4xl mb-3">🍽</div>
            <p style={{ fontFamily: "Outfit, sans-serif" }}>No recipes found</p>
          </div>
        )}
      </div>

      <TabBar active={activeTab} onSelect={onTab} />
    </div>
  );
}

// ─── Screen: AI Generate ─────────────────────────────────────────────────────

function AIGenerateScreen({
  onBack,
  onGenerated,
}: {
  onBack: () => void;
  onGenerated: () => void;
}) {
  const [ingredients, setIngredients] = useState("");
  const [tags, setTags] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [tipIndex, setTipIndex] = useState(0);
  const [diet, setDiet] = useState({ veg: false, vegan: false, gf: false });
  const [spice, setSpice] = useState(2);

  const tips = [
    "Checking what's seasonal right now...",
    "Matching your pantry to global cuisines...",
    "Asking the AI chef for inspiration...",
    "Crafting a perfect recipe just for you...",
  ];

  const addTag = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" || e.key === ",") {
      const val = ingredients.trim().replace(",", "");
      if (val && !tags.includes(val)) {
        setTags([...tags, val]);
        setIngredients("");
      }
    }
  };

  const removeTag = (t: string) => setTags(tags.filter((x) => x !== t));

  const generate = () => {
    setLoading(true);
    const interval = setInterval(() => {
      setTipIndex((i) => (i + 1) % tips.length);
    }, 1200);
    setTimeout(() => {
      clearInterval(interval);
      setLoading(false);
      onGenerated();
    }, 4000);
  };

  if (loading) {
    return (
      <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col items-center justify-center px-8">
        <div className="mb-8">
          <svg
            width="80"
            height="80"
            viewBox="0 0 80 80"
            className="spin-slow"
            style={{ animationDuration: "3s" }}
          >
            <circle
              cx="40"
              cy="40"
              r="30"
              fill="none"
              stroke="#D9713C"
              strokeWidth="3"
              strokeDasharray="8 6"
            />
            <text
              x="40"
              y="47"
              textAnchor="middle"
              fontSize="28"
              fill="#D9713C"
            >
              🍳
            </text>
          </svg>
        </div>
        <h2
          className="text-[#2B2420] text-xl mb-3 text-center"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          Generating your recipe...
        </h2>
        <p
          className="text-[#9C8F8A] text-sm text-center transition-all"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          {tips[tipIndex]}
        </p>
        <div className="mt-6 flex gap-1">
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              className="w-2 h-2 rounded-full bg-[#D9713C] opacity-60"
              style={{
                animation: `pulse 1.2s ease-in-out ${i * 0.2}s infinite`,
              }}
            />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col overflow-y-auto no-scrollbar">
      {/* Header */}
      <div className="pt-14 px-5 pb-6 text-center">
        <button onClick={onBack} className="absolute top-14 left-5 p-1">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path
              d="M15 18l-6-6 6-6"
              stroke="#2B2420"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </button>
        {/* Illustrated icon */}
        <div className="flex justify-center mb-4">
          <div className="w-20 h-20 rounded-full bg-[#D9713C]/10 flex items-center justify-center">
            <svg width="44" height="44" viewBox="0 0 44 44" fill="none">
              <path
                d="M8 32c0 2.2 1.8 4 4 4h20c2.2 0 4-1.8 4-4V22H8v10z"
                stroke="#D9713C"
                strokeWidth="1.8"
                fill="#D9713C"
                fillOpacity="0.12"
              />
              <path
                d="M8 22h28M14 22V14c0-1.1.9-2 2-2s2 .9 2 2v2M22 22V10c0-1.1.9-2 2-2s2 .9 2 2v12M30 22V14c0-1.1.9-2 2-2s2 .9 2 2v8"
                stroke="#D9713C"
                strokeWidth="1.8"
                strokeLinecap="round"
              />
            </svg>
          </div>
        </div>
        <h1
          className="text-[#2B2420] text-2xl"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          AI Recipe Generator
        </h1>
        <p
          className="text-[#9C8F8A] text-sm mt-1"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          Tell me what you have and I'll create something delicious.
        </p>
      </div>

      <div className="px-5 space-y-5 pb-8">
        {/* Ingredient input */}
        <div>
          <label
            className="text-[#5C4F4A] text-sm font-semibold mb-2 block"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            What ingredients do you have?
          </label>
          {tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-2">
              {tags.map((t) => (
                <span
                  key={t}
                  className="flex items-center gap-1 bg-[#8A9B6E]/15 text-[#8A9B6E] text-[13px] font-medium px-3 py-1 rounded-full"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {t}
                  <button
                    onClick={() => removeTag(t)}
                    className="text-[#8A9B6E] ml-0.5 opacity-70 hover:opacity-100"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          )}
          <input
            type="text"
            placeholder="Type ingredient + press Enter (e.g. chicken, garlic...)"
            value={ingredients}
            onChange={(e) => setIngredients(e.target.value)}
            onKeyDown={addTag}
            className="w-full bg-white border border-[rgba(43,36,32,0.1)] rounded-2xl px-4 py-3.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
        </div>

        {/* Dietary toggles */}
        <div>
          <label
            className="text-[#5C4F4A] text-sm font-semibold mb-3 block"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            Dietary restrictions
          </label>
          <div className="flex gap-2 flex-wrap">
            {[
              { key: "veg", label: "Vegetarian" },
              { key: "vegan", label: "Vegan" },
              { key: "gf", label: "Gluten-free" },
            ].map(({ key, label }) => (
              <button
                key={key}
                onClick={() => setDiet({ ...diet, [key]: !diet[key as keyof typeof diet] })}
                className={`px-4 py-2 rounded-full text-sm font-medium border transition-all ${
                  diet[key as keyof typeof diet]
                    ? "bg-[#8A9B6E] text-white border-[#8A9B6E]"
                    : "bg-white text-[#5C4F4A] border-[rgba(43,36,32,0.12)]"
                }`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Spice slider */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <label
              className="text-[#5C4F4A] text-sm font-semibold"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              Spice level
            </label>
            <span
              className="text-[#D9713C] text-sm font-semibold"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {["Mild", "Medium", "Hot", "Extra Hot", "🔥 Inferno"][spice]}
            </span>
          </div>
          <div className="relative">
            <div className="h-2 rounded-full bg-gradient-to-r from-[#FDF3EC] via-[#D9713C] to-[#8B1A1A] opacity-30 rounded-full" />
            <input
              type="range"
              min={0}
              max={4}
              value={spice}
              onChange={(e) => setSpice(Number(e.target.value))}
              className="absolute inset-0 w-full opacity-0 cursor-pointer h-2"
            />
            <div className="h-2 rounded-full overflow-hidden bg-[rgba(217,113,60,0.15)]">
              <div
                className="h-full rounded-full bg-gradient-to-r from-[#F2B68A] to-[#D9713C] transition-all"
                style={{ width: `${(spice / 4) * 100}%` }}
              />
            </div>
          </div>
        </div>

        {/* Generate button */}
        <button
          onClick={generate}
          className="w-full bg-[#D9713C] text-white py-4 rounded-full text-base font-semibold shadow-[0_4px_16px_rgba(217,113,60,0.35)] active:scale-[0.98] transition-transform flex items-center justify-center gap-2"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          <span className="text-lg">✦</span>
          Generate Recipe
        </button>
      </div>
    </div>
  );
}

// ─── Swap Ingredient Sheet ────────────────────────────────────────────────────

interface PairingSuggestion {
  id: string;
  name: string;
  reason: string;
  emoji: string;
  linkedRecipeId?: string; // maps to RECIPES[].id if the item exists in library
}

// Pools per cuisine; cycled via "Regenerate pairing" button
const PAIRING_POOLS: Record<string, PairingSuggestion[][]> = {
  Italian: [
    [
      { id: "p1", name: "Garlic Bread", reason: "Crispy and aromatic — perfect for mopping up sauce", emoji: "🥖", linkedRecipeId: "3" },
      { id: "p2", name: "Simple Arugula Salad", reason: "Peppery greens cut through the richness of pasta", emoji: "🥗" },
    ],
    [
      { id: "p3", name: "Bruschetta", reason: "Fresh tomatoes echo the sauce and add crunch", emoji: "🍅" },
      { id: "p4", name: "Sparkling Lemonade", reason: "Bright acidity lifts heavy, cheesy dishes", emoji: "🍋" },
    ],
    [
      { id: "p5", name: "Tiramisu", reason: "Classic Italian finish — coffee notes balance tomato acidity", emoji: "☕" },
    ],
  ],
  Indian: [
    [
      { id: "p6", name: "Basmati Rice", reason: "Fluffy grains soak up the curry perfectly", emoji: "🍚" },
      { id: "p7", name: "Mango Lassi", reason: "Cool, sweet dairy tames the spice beautifully", emoji: "🥭" },
    ],
    [
      { id: "p8", name: "Garlic Naan", reason: "Pillowy bread for scooping rich sauces", emoji: "🫓" },
      { id: "p9", name: "Cucumber Raita", reason: "Yogurt and cucumber cool the palate between bites", emoji: "🥒" },
    ],
  ],
  Japanese: [
    [
      { id: "p10", name: "Miso Soup", reason: "Umami-rich broth rounds out the meal", emoji: "🍜" },
      { id: "p11", name: "Pickled Ginger", reason: "Cleanses the palate between bites", emoji: "🫚" },
    ],
  ],
  Thai: [
    [
      { id: "p12", name: "Jasmine Rice", reason: "Fragrant and light — balances bold Thai flavours", emoji: "🍚" },
      { id: "p13", name: "Thai Iced Tea", reason: "Creamy sweetness offsets heat and spice", emoji: "🧋" },
    ],
  ],
  Mediterranean: [
    [
      { id: "p14", name: "Warm Pita Bread", reason: "Scoopable and neutral to balance bold flavours", emoji: "🫓" },
      { id: "p15", name: "Tzatziki", reason: "Cool yogurt-cucumber dip is a natural counterpoint", emoji: "🥒" },
    ],
  ],
  American: [
    [
      { id: "p16", name: "Coleslaw", reason: "Crunchy and tangy — a classic American pairing", emoji: "🥗" },
      { id: "p17", name: "Lemonade", reason: "Bright citrus refreshes between hearty bites", emoji: "🍋" },
    ],
  ],
};

const DEFAULT_PAIRINGS: PairingSuggestion[][] = [
  [
    { id: "pd1", name: "Simple Green Salad", reason: "Light greens refresh the palate between bites", emoji: "🥗" },
    { id: "pd2", name: "Sparkling Water with Lime", reason: "Clean and bright to balance rich flavours", emoji: "🫧" },
  ],
  [
    { id: "pd3", name: "Crusty Bread Roll", reason: "Perfect for soaking up any leftover sauce", emoji: "🥐" },
  ],
];

function getPairingPool(cuisine: string): PairingSuggestion[][] {
  return PAIRING_POOLS[cuisine] ?? DEFAULT_PAIRINGS;
}

const SWAP_SUGGESTIONS: Record<string, { replacement: string; note: string }> = {
  "400g spaghetti":                    { replacement: "400g linguine or fettuccine", note: "Same cook time. Wider noodles will hold slightly more sauce." },
  "2 cans San Marzano tomatoes (400g each)": { replacement: "800g fresh Roma tomatoes, blanched & peeled", note: "Add 5 min extra simmer time to reduce extra liquid." },
  "4 cloves garlic, minced":           { replacement: "1 tsp garlic powder", note: "Add with the tomatoes instead of the oil; use ¾ tsp if you prefer milder flavour." },
  "1 small shallot, finely diced":     { replacement: "¼ medium white onion, finely diced", note: "Slightly sharper flavour — sauté 1 min longer until fully soft." },
  "3 tbsp extra-virgin olive oil":     { replacement: "3 tbsp light olive oil or avocado oil", note: "Same quantity. Avocado oil has a higher smoke point — great for higher heat." },
  "1 tsp sugar":                       { replacement: "½ tsp honey or a pinch of baking soda", note: "Baking soda neutralises acidity without adding sweetness. Use sparingly." },
  "Fresh basil leaves":                { replacement: "1 tsp dried basil", note: "Add with the tomatoes rather than at the end. Use ½ tsp — dried is more concentrated." },
  "Salt and black pepper":             { replacement: "Soy sauce + white pepper", note: "Use ½ tsp soy sauce for salt; white pepper is milder. Adds a subtle umami note." },
  "Parmesan cheese, for serving":      { replacement: "Pecorino Romano or nutritional yeast (vegan)", note: "Pecorino is saltier — reduce added salt by a pinch. Nutritional yeast: 2 tbsp per serving." },
};

function SwapIngredientSheet({
  ingredient,
  onClose,
  onConfirm,
}: {
  ingredient: string;
  onClose: () => void;
  onConfirm: (replacement: string, note: string) => void;
}) {
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [suggestion, setSuggestion] = useState<{ replacement: string; note: string } | null>(null);

  const ask = () => {
    if (!input.trim()) return;
    setLoading(true);
    setSuggestion(null);
    setTimeout(() => {
      const preset = SWAP_SUGGESTIONS[ingredient];
      setSuggestion(
        preset ?? {
          replacement: input.trim(),
          note: "Looks like a reasonable swap! Adjust seasoning to taste and keep an eye on cook time.",
        },
      );
      setLoading(false);
    }, 1400);
  };

  return (
    <div className="absolute inset-0 flex flex-col justify-end z-30">
      <button onClick={onClose} className="absolute inset-0 bg-black/40" />
      <div className="relative bg-[#FDF8F3] rounded-t-[28px] shadow-[0_-8px_40px_rgba(0,0,0,0.18)] sheet-enter">
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 rounded-full bg-[rgba(43,36,32,0.15)]" />
        </div>

        <div className="px-5 pb-10 pt-2">
          {/* Header */}
          <div className="flex items-start justify-between mb-4">
            <div className="flex-1 mr-3">
              <h2
                className="text-[#2B2420] text-lg"
                style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
              >
                Swap Ingredient
              </h2>
              <p
                className="text-[#9C8F8A] text-[12px] mt-0.5 leading-snug"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                Replacing:{" "}
                <span className="text-[#5C4F4A] font-medium">{ingredient}</span>
              </p>
            </div>
            <button onClick={onClose} className="p-1 mt-0.5">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path d="M18 6L6 18M6 6l12 12" stroke="#9C8F8A" strokeWidth="2" strokeLinecap="round" />
              </svg>
            </button>
          </div>

          {/* Input row */}
          <div className="flex gap-2 mb-4">
            <input
              type="text"
              placeholder="What do you have instead?"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && ask()}
              autoFocus
              className="flex-1 bg-white border border-[rgba(43,36,32,0.12)] rounded-2xl px-4 py-3 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
              style={{ fontFamily: "Outfit, sans-serif" }}
            />
            <button
              onClick={ask}
              disabled={!input.trim() || loading}
              className="w-11 h-11 mt-0.5 rounded-full bg-[#D9713C] flex items-center justify-center flex-shrink-0 shadow-[0_2px_10px_rgba(217,113,60,0.3)] disabled:opacity-40 transition-opacity"
            >
              <span className="text-white text-base">✦</span>
            </button>
          </div>

          {/* Loading state */}
          {loading && (
            <div className="flex items-center gap-2 py-3 px-4 bg-white rounded-2xl border border-[rgba(43,36,32,0.07)]">
              <div className="flex gap-1">
                {[0, 1, 2].map((i) => (
                  <div
                    key={i}
                    className="w-1.5 h-1.5 rounded-full bg-[#D9713C]"
                    style={{ animation: `simmerBubble 1s ease-in-out ${i * 0.18}s infinite` }}
                  />
                ))}
              </div>
              <span className="text-[#9C8F8A] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>
                Finding the best substitute...
              </span>
            </div>
          )}

          {/* AI suggestion */}
          {suggestion && (
            <div className="bg-white rounded-2xl border border-[rgba(43,36,32,0.08)] overflow-hidden">
              {/* AI label */}
              <div className="flex items-center gap-1.5 px-4 pt-3 pb-2 border-b border-[rgba(43,36,32,0.06)]">
                <span className="text-[#D9713C] text-[13px]">✦</span>
                <span
                  className="text-[11px] font-semibold text-[#D9713C] uppercase tracking-wide"
                  style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.07em" }}
                >
                  AI Suggestion
                </span>
              </div>
              <div className="px-4 pt-3 pb-2">
                <p
                  className="text-[#2B2420] text-sm font-semibold mb-1"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {suggestion.replacement}
                </p>
                {/* Adjustment note */}
                <div className="flex gap-2 mt-2 bg-[#8A9B6E]/08 rounded-xl px-3 py-2.5" style={{ background: "rgba(138,155,110,0.08)" }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" className="flex-shrink-0 mt-0.5">
                    <circle cx="12" cy="12" r="9" stroke="#8A9B6E" strokeWidth="1.8" />
                    <path d="M12 8v4M12 16h.01" stroke="#8A9B6E" strokeWidth="1.8" strokeLinecap="round" />
                  </svg>
                  <p
                    className="text-[#5C4F4A] text-[12px] leading-relaxed"
                    style={{ fontFamily: "Outfit, sans-serif" }}
                  >
                    {suggestion.note}
                  </p>
                </div>
              </div>
              {/* Confirm button */}
              <div className="px-4 pb-4 pt-2">
                <button
                  onClick={() => onConfirm(suggestion.replacement, suggestion.note)}
                  className="w-full bg-[#D9713C] text-white py-3 rounded-full text-sm font-semibold shadow-[0_3px_12px_rgba(217,113,60,0.3)] active:scale-[0.98] transition-transform"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  Use this swap
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Screen: Recipe Overview ──────────────────────────────────────────────────

interface RecipeComment {
  id: string;
  user: string;
  avatarColor: string;
  text: string;
  time: string;
}

const SEED_COMMENTS: RecipeComment[] = [
  { id: "c1", user: "naomi_cooks", avatarColor: "#8A9B6E", text: "Made this last night — incredible depth of flavour from the San Marzanos. I added a small parmesan rind while simmering.", time: "2h ago" },
  { id: "c2", user: "chef_marco", avatarColor: "#D9713C", text: "Classic! I swap the shallot for red onion when I want a bit more bite.", time: "5h ago" },
  { id: "c3", user: "yuki_eats", avatarColor: "#9C8F8A", text: "Beautiful recipe. Does this work well with gluten-free pasta?", time: "Yesterday" },
];

function RecipeOverviewScreen({
  recipe: initialRecipe,
  onBack,
  onStartCooking,
  onAddNotification,
  onAddToGrocery,
  rating,
  onRate,
}: {
  recipe: Recipe;
  onBack: () => void;
  onStartCooking: () => void;
  onAddNotification?: (n: Omit<Notification, "id" | "read">) => void;
  onAddToGrocery?: (items: Omit<GroceryItem, "id" | "checked">[]) => void;
  rating?: RecipeRatingData;
  onRate?: (stars: number) => void;
}) {
  const [recipe, setRecipe] = useState(initialRecipe);
  const [checked, setChecked] = useState<Set<number>>(new Set());
  const [showSteps, setShowSteps] = useState(false);
  const [expandedSwap, setExpandedSwap] = useState<number | null>(null);
  const [swapSheet, setSwapSheet] = useState<{ index: number; ing: string } | null>(null);
  const [swaps, setSwaps] = useState<Record<number, { replacement: string; note: string }>>({});
  const [lightbox, setLightbox] = useState(false);
  const [liked, setLiked] = useState(false);
  const [likeCount, setLikeCount] = useState((initialRecipe as CommunityRecipe).likes ?? 248);
  const [saved, setSaved] = useState(false);
  const [comments, setComments] = useState<RecipeComment[]>(SEED_COMMENTS);
  const [commentInput, setCommentInput] = useState("");
  const [regenerating, setRegenerating] = useState(false);
  const [toastVisible, setToastVisible] = useState(false);
  const [rateSheet, setRateSheet] = useState(false);
  const [myRating, setMyRating] = useState(0);
  const [pairingIndex, setPairingIndex] = useState(0);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const variationIndexRef = useRef(0);

  const isAI = recipe.isAIGenerated === true;

  const handleRegenerate = () => {
    setRegenerating(true);
    setTimeout(() => {
      const next = AI_VARIATIONS[variationIndexRef.current % AI_VARIATIONS.length];
      variationIndexRef.current += 1;
      setRecipe(next);
      setChecked(new Set());
      setSwaps({});
      setExpandedSwap(null);
      setShowSteps(false);
      setRegenerating(false);
    }, 1800);
  };

  const handleAddToGrocery = (ings: string[]) => {
    onAddToGrocery?.(
      ings.map((name) => ({ name, recipeTitle: recipe.title, category: tagCategory(name) }))
    );
    setToastVisible(true);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToastVisible(false), 2800);
  };

  const baseIngredients = [
    "400g spaghetti",
    "2 cans San Marzano tomatoes (400g each)",
    "4 cloves garlic, minced",
    "1 small shallot, finely diced",
    "3 tbsp extra-virgin olive oil",
    "1 tsp sugar",
    "Fresh basil leaves",
    "Salt and black pepper",
    "Parmesan cheese, for serving",
  ];

  // Displayed ingredient text accounts for active swaps
  const ingredients = baseIngredients.map((ing, i) =>
    swaps[i] ? swaps[i].replacement : ing,
  );

  const toggle = (i: number) => {
    const s = new Set(checked);
    if (s.has(i)) s.delete(i);
    else s.add(i);
    setChecked(s);
  };

  const handleRowTap = (i: number) => {
    // If the swap action row is already open for this index, close it
    setExpandedSwap((prev) => (prev === i ? null : i));
  };

  const confirmSwap = (index: number, replacement: string, note: string) => {
    setSwaps((prev) => ({ ...prev, [index]: { replacement, note } }));
    setSwapSheet(null);
    setExpandedSwap(null);
  };

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col overflow-y-auto no-scrollbar">
      {lightbox && (
        <FullscreenImageViewer src={recipe.image} alt={recipe.title} onClose={() => setLightbox(false)} />
      )}

      {/* Grocery toast */}
      <div
        className="absolute bottom-28 left-5 right-5 z-40 pointer-events-none"
        style={{
          transform: toastVisible ? "translateY(0)" : "translateY(16px)",
          opacity: toastVisible ? 1 : 0,
          transition: "transform 0.3s cubic-bezier(0.32,0.72,0,1), opacity 0.25s ease",
        }}
      >
        <div
          className="flex items-center gap-3 px-4 py-3 rounded-2xl shadow-[0_8px_32px_rgba(43,36,32,0.18)]"
          style={{ background: "#2B2420" }}
        >
          <div className="w-8 h-8 rounded-full bg-[#8A9B6E] flex items-center justify-center flex-shrink-0">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
              <path d="M20 6L9 17l-5-5" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div>
            <p className="text-white text-[13px] font-semibold leading-tight" style={{ fontFamily: "Outfit, sans-serif" }}>
              Added {ingredients.length} items to your Grocery List
            </p>
            <p className="text-white/50 text-[11px] mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>
              {recipe.title}
            </p>
          </div>
        </div>
      </div>

      {/* Hero Image */}
      <div className="relative">
        <div className="relative bg-[#E8DDD5]" style={{ height: "338px" }}>
          <img
            src={recipe.image}
            alt={recipe.title}
            className="absolute inset-0 w-full h-full object-cover cursor-zoom-in"
            onClick={() => setLightbox(true)}
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent pointer-events-none" />
          {/* Expand hint */}
          <div className="absolute bottom-16 right-4 pointer-events-none">
            <div className="w-8 h-8 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
          {/* Back button */}
          <button
            onClick={onBack}
            className="absolute top-12 left-4 w-10 h-10 rounded-full bg-white/80 backdrop-blur-sm flex items-center justify-center shadow-sm"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path
                d="M15 18l-6-6 6-6"
                stroke="#2B2420"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
          {/* Action icons */}
          <div className="absolute top-12 right-4 flex gap-2">
            {/* Bookmark / Save */}
            <button
              onClick={() => setSaved((v) => !v)}
              className={`w-10 h-10 rounded-full backdrop-blur-sm flex items-center justify-center shadow-sm transition-all ${saved ? "bg-[#D9713C]" : "bg-white/80"}`}
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M5 3h14a1 1 0 011 1v17l-8-4-8 4V4a1 1 0 011-1z" stroke={saved ? "white" : "#2B2420"} strokeWidth="1.75" fill={saved ? "white" : "none"} />
              </svg>
            </button>
            {/* Share */}
            <button className="w-10 h-10 rounded-full bg-white/80 backdrop-blur-sm flex items-center justify-center shadow-sm">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <circle cx="18" cy="5" r="2" stroke="#2B2420" strokeWidth="1.75" />
                <circle cx="6" cy="12" r="2" stroke="#2B2420" strokeWidth="1.75" />
                <circle cx="18" cy="19" r="2" stroke="#2B2420" strokeWidth="1.75" />
                <path d="M8 10.5l8-4M8 13.5l8 4" stroke="#2B2420" strokeWidth="1.75" />
              </svg>
            </button>
          </div>

          {/* Glass card floating over bottom of image */}
          <div className="absolute bottom-0 left-4 right-4 translate-y-1/3">
            <div className="glass-card rounded-[20px] p-4 shadow-[0_8px_32px_rgba(43,36,32,0.12)]">
              <div className="flex items-start justify-between mb-2">
                <h1
                  className="text-[#2B2420] text-lg leading-tight flex-1 mr-2"
                  style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
                >
                  {recipe.title}
                </h1>
                <div className="flex items-center gap-2 flex-shrink-0">
                  {/* Like button */}
                  <button
                    onClick={() => {
                      const next = !liked;
                      setLiked(next);
                      setLikeCount((c) => c + (next ? 1 : -1));
                      if (next) onAddNotification?.({ type: "liked", fromUser: "you", avatarColor: "#D9713C", recipeName: recipe.title, recipeId: recipe.id, timestamp: "Just now" });
                    }}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-full transition-all active:scale-95"
                    style={{ background: liked ? "rgba(217,113,60,0.12)" : "rgba(43,36,32,0.06)" }}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill={liked ? "#D9713C" : "none"}>
                      <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" stroke={liked ? "#D9713C" : "#5C4F4A"} strokeWidth="1.6" />
                    </svg>
                    <span className="text-[12px] font-semibold" style={{ fontFamily: "Outfit, sans-serif", color: liked ? "#D9713C" : "#5C4F4A" }}>{likeCount}</span>
                  </button>
                  <span className="flex-shrink-0 bg-[#D9713C]/15 text-[#D9713C] text-[11px] font-semibold px-2.5 py-1 rounded-full" style={{ fontFamily: "Outfit, sans-serif" }}>
                    {recipe.cuisine}
                  </span>
                </div>
              </div>
              <div className="flex gap-4">
                {[
                  { icon: "⏱", label: recipe.time },
                  { icon: "👥", label: `${recipe.servings} servings` },
                  { icon: "📊", label: recipe.difficulty },
                ].map((item) => (
                  <div key={item.label} className="text-center">
                    <div className="text-base">{item.icon}</div>
                    <div
                      className="text-[11px] text-[#5C4F4A] font-medium mt-0.5"
                      style={{ fontFamily: "Outfit, sans-serif" }}
                    >
                      {item.label}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="mt-20 px-5 pb-32">
        {/* Uploader attribution */}
        {recipe.uploader && (
          <div className="mb-5">
            <UploaderAttribution uploader={recipe.uploader} avatarColor={recipe.avatarColor} size="md" />
          </div>
        )}

        {/* Rating row */}
        {rating && (
          <button
            onClick={() => setRateSheet(true)}
            className="w-full flex items-center justify-between mb-5 px-4 py-3 rounded-2xl active:scale-[0.98] transition-transform"
            style={{ background: "rgba(200,146,10,0.07)", border: "1px solid rgba(200,146,10,0.18)" }}
          >
            <div className="flex items-center gap-2">
              <StarRating average={rating.average} count={rating.count} size={16} />
            </div>
            <span className="text-[12px] font-semibold text-[#C8920A]" style={{ fontFamily: "Outfit, sans-serif" }}>
              Rate this recipe →
            </span>
          </button>
        )}

        {/* Ingredients header + grocery button */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[#2B2420] text-lg" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>
            Ingredients
          </h2>
          <button
            onClick={() => handleAddToGrocery(ingredients)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full active:scale-95 transition-transform"
            style={{ background: "rgba(138,155,110,0.12)", border: "1px solid rgba(138,155,110,0.25)" }}
          >
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
              <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke="#8A9B6E" strokeWidth="1.75" strokeLinejoin="round" />
              <path d="M3 6h18" stroke="#8A9B6E" strokeWidth="1.75" strokeLinecap="round" />
              <path d="M16 10a4 4 0 01-8 0" stroke="#8A9B6E" strokeWidth="1.75" strokeLinecap="round" />
            </svg>
            <span className="text-[12px] font-semibold text-[#8A9B6E]" style={{ fontFamily: "Outfit, sans-serif" }}>
              Add to List
            </span>
          </button>
        </div>
        <div className="space-y-1 mb-6">
          {ingredients.map((ing, i) => {
            const isSwapped = Boolean(swaps[i]);
            const isExpanded = expandedSwap === i;
            const isChecked = checked.has(i);
            return (
              <div key={i}>
                {/* Main ingredient row */}
                <div className="flex items-center gap-3 py-2">
                  {/* Checkbox */}
                  <button
                    onClick={() => toggle(i)}
                    className={`w-5 h-5 rounded-md flex-shrink-0 flex items-center justify-center border transition-all ${
                      isChecked
                        ? "bg-[#8A9B6E] border-[#8A9B6E]"
                        : "border-[rgba(43,36,32,0.2)] bg-white"
                    }`}
                  >
                    {isChecked && (
                      <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                        <path d="M2 6l3 3 5-5" stroke="white" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    )}
                  </button>

                  {/* Ingredient text + badges */}
                  <button
                    onClick={() => handleRowTap(i)}
                    className="flex-1 flex items-center gap-2 text-left active:opacity-70 transition-opacity"
                  >
                    <span
                      className={`text-sm leading-snug transition-all ${isChecked ? "text-[#9C8F8A] line-through" : "text-[#2B2420]"}`}
                      style={{ fontFamily: "Outfit, sans-serif" }}
                    >
                      {ing}
                    </span>
                    {isSwapped && (
                      <span
                        className="flex-shrink-0 inline-flex items-center gap-1 bg-[#8A9B6E]/15 text-[#8A9B6E] text-[10px] font-semibold px-2 py-0.5 rounded-full"
                        style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.03em" }}
                      >
                        <svg width="8" height="8" viewBox="0 0 10 10" fill="none">
                          <path d="M1 5h8M6 2l3 3-3 3" stroke="#8A9B6E" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                        swapped
                      </span>
                    )}
                  </button>

                  {/* Expand chevron */}
                  <button
                    onClick={() => handleRowTap(i)}
                    className="p-1 opacity-40 active:opacity-70 transition-all"
                    style={{ transform: isExpanded ? "rotate(180deg)" : "rotate(0deg)", transition: "transform 0.2s" }}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                      <path d="M6 9l6 6 6-6" stroke="#5C4F4A" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </button>
                </div>

                {/* Inline swap action — expands below the row */}
                {isExpanded && (
                  <div className="ml-8 mb-1 flex items-center gap-2 py-2 px-3 rounded-xl bg-[#FDF3EC] border border-[rgba(217,113,60,0.15)]">
                    {isSwapped ? (
                      <>
                        <span className="text-[12px] text-[#5C4F4A] flex-1" style={{ fontFamily: "Outfit, sans-serif" }}>
                          Using <span className="font-semibold text-[#2B2420]">{swaps[i].replacement}</span>
                        </span>
                        <button
                          onClick={() => {
                            setSwaps((prev) => { const n = { ...prev }; delete n[i]; return n; });
                            setExpandedSwap(null);
                          }}
                          className="text-[11px] text-[#9C8F8A] font-medium underline underline-offset-2"
                          style={{ fontFamily: "Outfit, sans-serif" }}
                        >
                          Undo
                        </button>
                      </>
                    ) : (
                      <>
                        <span className="text-[12px] text-[#5C4F4A]" style={{ fontFamily: "Outfit, sans-serif" }}>
                          Don't have this?
                        </span>
                        <button
                          onClick={() => setSwapSheet({ index: i, ing: baseIngredients[i] })}
                          className="flex items-center gap-1 bg-[#D9713C] text-white text-[11px] font-semibold px-3 py-1.5 rounded-full shadow-[0_2px_6px_rgba(217,113,60,0.25)] active:scale-[0.97] transition-transform"
                          style={{ fontFamily: "Outfit, sans-serif" }}
                        >
                          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                            <path d="M1 5h8M6 2l3 3-3 3" stroke="white" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
                          </svg>
                          Swap ingredient
                        </button>
                      </>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Active swaps summary */}
        {Object.keys(swaps).length > 0 && (
          <div className="mb-5 px-4 py-3 rounded-2xl bg-[#8A9B6E]/08 border border-[rgba(138,155,110,0.2)]" style={{ background: "rgba(138,155,110,0.07)" }}>
            <p className="text-[11px] font-semibold text-[#8A9B6E] uppercase tracking-wide mb-1" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.07em" }}>
              {Object.keys(swaps).length} ingredient{Object.keys(swaps).length > 1 ? "s" : ""} swapped
            </p>
            <p className="text-[12px] text-[#5C4F4A]" style={{ fontFamily: "Outfit, sans-serif" }}>
              Recipe adapted · AI notes saved for Cook Mode
            </p>
          </div>
        )}

        {/* ── Estimated Nutrition ── */}
        <div
          className="rounded-2xl overflow-hidden mb-6"
          style={{
            background: "#FEFAF5",
            border: "1px solid rgba(138,155,110,0.18)",
            borderLeft: "3px solid #8A9B6E",
            boxShadow: "0 1px 8px rgba(43,36,32,0.05)",
          }}
        >
          {/* Header row */}
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-2">
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
              <path d="M6 1l1.1 3.5H11L8.2 6.6l1.1 3.5L6 8l-3.3 2.1 1.1-3.5L1 4.5h3.9L6 1z" fill="#8A9B6E" />
            </svg>
            <span
              className="text-[11px] font-bold uppercase tracking-wide text-[#8A9B6E]"
              style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.07em" }}
            >
              AI Estimated · Per Serving
            </span>
          </div>

          {/* Stat blocks */}
          <div className="grid grid-cols-4 gap-0 px-3 pb-3">
            {[
              { label: "Calories", value: "487", unit: "kcal" },
              { label: "Protein",  value: "18",  unit: "g" },
              { label: "Carbs",    value: "62",  unit: "g" },
              { label: "Fat",      value: "16",  unit: "g" },
            ].map((stat, i, arr) => (
              <div
                key={stat.label}
                className="flex flex-col items-center py-2.5"
                style={{
                  borderRight: i < arr.length - 1 ? "1px solid rgba(138,155,110,0.15)" : "none",
                }}
              >
                <span
                  className="text-[20px] font-bold text-[#2B2420] leading-none"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {stat.value}
                </span>
                <span
                  className="text-[10px] text-[#9C8F8A] mt-0.5 font-medium"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {stat.unit}
                </span>
                <span
                  className="text-[10px] text-[#C4B8B3] mt-0.5"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {stat.label}
                </span>
              </div>
            ))}
          </div>

          {/* Disclaimer */}
          <div className="px-4 pb-3 pt-0">
            <p
              className="text-[10px] text-[#C4B8B3] leading-relaxed"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              AI estimate based on ingredients — may vary.
            </p>
          </div>
        </div>

        {/* Instructions Preview Accordion */}
        <button
          onClick={() => setShowSteps(!showSteps)}
          className="w-full flex items-center justify-between py-4 border-t border-b border-[rgba(43,36,32,0.08)] mb-6"
        >
          <div>
            <h2
              className="text-[#2B2420] text-base font-semibold text-left"
              style={{ fontFamily: "Lora, serif" }}
            >
              Instructions Preview
            </h2>
            <p
              className="text-[#9C8F8A] text-xs mt-0.5"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {COOK_STEPS.length} steps total
            </p>
          </div>
          <div
            className={`transition-transform ${showSteps ? "rotate-180" : ""}`}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path
                d="M6 9l6 6 6-6"
                stroke="#9C8F8A"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
        </button>

        {showSteps && (
          <div className="space-y-3 mb-6">
            {COOK_STEPS.map((step) => (
              <div key={step.step} className="flex gap-3">
                <div className="w-6 h-6 rounded-full bg-[#D9713C]/15 flex-shrink-0 flex items-center justify-center mt-0.5">
                  <span
                    className="text-[11px] font-bold text-[#D9713C]"
                    style={{ fontFamily: "Outfit, sans-serif" }}
                  >
                    {step.step}
                  </span>
                </div>
                <p
                  className="text-sm text-[#5C4F4A] leading-relaxed"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {step.text}
                </p>
              </div>
            ))}
          </div>
        )}

        {/* AI Pairing Suggestion */}
        {(() => {
          const pool = getPairingPool(recipe.cuisine);
          const pairings = pool[pairingIndex % pool.length];
          return (
            <div className="mb-6 rounded-[20px] overflow-hidden" style={{ background: "linear-gradient(135deg, rgba(217,113,60,0.09) 0%, rgba(217,113,60,0.04) 100%)", border: "1px solid rgba(217,113,60,0.18)" }}>
              {/* Header */}
              <div className="flex items-center justify-between px-4 pt-4 pb-3">
                <div className="flex items-center gap-2">
                  <span style={{ fontSize: 15, lineHeight: 1 }}>✦</span>
                  <span className="text-[#D9713C] text-[12px] font-bold uppercase tracking-wider" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.07em" }}>
                    AI Suggests Pairing With
                  </span>
                </div>
                <button
                  onClick={() => setPairingIndex((i) => i + 1)}
                  className="w-7 h-7 rounded-full flex items-center justify-center active:scale-90 transition-transform"
                  style={{ background: "rgba(217,113,60,0.10)" }}
                  title="Regenerate pairing"
                >
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
                    <path d="M1 4v6h6" stroke="#D9713C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                    <path d="M23 20v-6h-6" stroke="#D9713C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                    <path d="M20.49 9A9 9 0 005.64 5.64L1 10M23 14l-4.64 4.36A9 9 0 013.51 15" stroke="#D9713C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </button>
              </div>

              {/* Pairing cards */}
              <div className={`px-4 pb-4 ${pairings.length > 1 ? "grid grid-cols-2 gap-3" : ""}`}>
                {pairings.map((p) => (
                  <div
                    key={p.id}
                    className="bg-white/70 rounded-[14px] p-3"
                    style={{ backdropFilter: "blur(8px)", border: "1px solid rgba(217,113,60,0.10)" }}
                  >
                    <div className="flex items-start gap-2 mb-1.5">
                      <div
                        className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 text-lg"
                        style={{ background: "rgba(217,113,60,0.10)" }}
                      >
                        {p.emoji}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-[#2B2420] text-[13px] font-semibold leading-snug" style={{ fontFamily: "Lora, serif" }}>
                          {p.name}
                        </p>
                      </div>
                    </div>
                    <p className="text-[#9C8F8A] text-[11px] leading-relaxed mb-2" style={{ fontFamily: "Outfit, sans-serif" }}>
                      {p.reason}
                    </p>
                    {p.linkedRecipeId ? (
                      <span className="inline-flex items-center gap-1 text-[#D9713C] text-[11px] font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>
                        See Recipe
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
                          <path d="M5 12h14M12 5l7 7-7 7" stroke="#D9713C" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      </span>
                    ) : (
                      <span className="inline-block text-[#C4B8B3] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>
                        Suggestion only
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          );
        })()}

        {/* Regenerate with AI — only for AI-generated recipes */}
        {isAI ? (
          <button
            onClick={handleRegenerate}
            disabled={regenerating}
            className="w-full flex items-center justify-center gap-2 py-3 rounded-2xl border border-[rgba(217,113,60,0.3)] bg-[rgba(217,113,60,0.04)] text-[#D9713C] text-sm font-semibold mb-5 active:scale-[0.98] transition-all disabled:opacity-60"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            {regenerating ? (
              <>
                <svg className="spin-slow" width="15" height="15" viewBox="0 0 24 24" fill="none">
                  <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" stroke="#D9713C" strokeWidth="2" strokeLinecap="round" />
                </svg>
                Creating a new variation…
              </>
            ) : (
              <>
                <span style={{ fontSize: 15 }}>✦</span>
                Regenerate with AI
              </>
            )}
          </button>
        ) : (
          /* Save + Share row — shown for fixed/community recipes in place of regenerate */
          <div className="flex gap-3 mb-5">
            <button
              onClick={() => setSaved((v) => !v)}
              className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-2xl border text-sm font-semibold transition-all active:scale-[0.98] ${saved ? "bg-[#8A9B6E]/12 border-[rgba(138,155,110,0.35)] text-[#8A9B6E]" : "border-[rgba(43,36,32,0.1)] text-[#5C4F4A]"}`}
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill={saved ? "#8A9B6E" : "none"}>
                <path d="M5 3h14a1 1 0 011 1v17l-8-4-8 4V4a1 1 0 011-1z" stroke={saved ? "#8A9B6E" : "#5C4F4A"} strokeWidth="1.75" />
              </svg>
              {saved ? "Saved" : "Save Recipe"}
            </button>
            <button
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-2xl border border-[rgba(43,36,32,0.1)] text-[#5C4F4A] text-sm font-semibold active:scale-[0.98] transition-all"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
                <circle cx="18" cy="5" r="2" stroke="#5C4F4A" strokeWidth="1.75" />
                <circle cx="6" cy="12" r="2" stroke="#5C4F4A" strokeWidth="1.75" />
                <circle cx="18" cy="19" r="2" stroke="#5C4F4A" strokeWidth="1.75" />
                <path d="M8 10.5l8-4M8 13.5l8 4" stroke="#5C4F4A" strokeWidth="1.75" />
              </svg>
              Share
            </button>
          </div>
        )}

        {/* Start Cooking */}
        <button
          onClick={() => {
            onAddNotification?.({ type: "cooked", fromUser: "you", avatarColor: "#D9713C", recipeName: recipe.title, recipeId: recipe.id, timestamp: "Just now" });
            onStartCooking();
          }}
          className="w-full bg-[#D9713C] text-white py-4 rounded-full text-base font-semibold shadow-[0_4px_20px_rgba(217,113,60,0.35)] active:scale-[0.98] transition-transform"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          Start Cooking
        </button>

        {/* ── Comments ── */}
        <div className="mt-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-[#2B2420] text-lg" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Comments</h2>
            <span className="text-[#9C8F8A] text-[13px]" style={{ fontFamily: "Outfit, sans-serif" }}>{comments.length}</span>
          </div>

          {/* Comment input */}
          <div className="flex gap-3 mb-5">
            <div className="w-8 h-8 rounded-full bg-[#D9713C]/20 flex-shrink-0 flex items-center justify-center">
              <span className="text-[13px] font-bold text-[#D9713C]" style={{ fontFamily: "Lora, serif" }}>A</span>
            </div>
            <div className="flex-1 flex gap-2">
              <input
                type="text"
                placeholder="Add a comment…"
                value={commentInput}
                onChange={(e) => setCommentInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && commentInput.trim()) {
                    const newC: RecipeComment = { id: String(Date.now()), user: "you", avatarColor: "#D9713C", text: commentInput.trim(), time: "Just now" };
                    setComments([newC, ...comments]);
                    setCommentInput("");
                    onAddNotification?.({ type: "commented", fromUser: "you", avatarColor: "#D9713C", recipeName: recipe.title, recipeId: recipe.id, timestamp: "Just now" });
                  }
                }}
                className="flex-1 bg-[rgba(43,36,32,0.05)] rounded-full px-4 py-2 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none border border-[rgba(43,36,32,0.07)]"
                style={{ fontFamily: "Outfit, sans-serif" }}
              />
              <button
                onClick={() => {
                  if (!commentInput.trim()) return;
                  const newC: RecipeComment = { id: String(Date.now()), user: "you", avatarColor: "#D9713C", text: commentInput.trim(), time: "Just now" };
                  setComments([newC, ...comments]);
                  setCommentInput("");
                  onAddNotification?.({ type: "commented", fromUser: "you", avatarColor: "#D9713C", recipeName: recipe.title, recipeId: recipe.id, timestamp: "Just now" });
                }}
                className="w-9 h-9 rounded-full bg-[#D9713C] flex items-center justify-center flex-shrink-0 active:scale-95 transition-transform"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                  <path d="M22 2L11 13M22 2L15 22l-4-9-9-4 20-7z" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </div>
          </div>

          {/* Comment list — newest first */}
          <div className="space-y-4 pb-4">
            {comments.map((c) => (
              <div key={c.id} className="flex gap-3">
                <div className="w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center text-white text-[12px] font-bold" style={{ background: c.avatarColor, fontFamily: "Lora, serif" }}>
                  {c.user[0].toUpperCase()}
                </div>
                <div className="flex-1 bg-white rounded-2xl rounded-tl-sm px-4 py-3 shadow-[0_1px_6px_rgba(43,36,32,0.06)]">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-[#2B2420] text-[13px] font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>@{c.user}</span>
                    <span className="text-[#C4B8B3] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>{c.time}</span>
                  </div>
                  <p className="text-[#5C4F4A] text-sm leading-relaxed" style={{ fontFamily: "Outfit, sans-serif" }}>{c.text}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Swap ingredient bottom sheet */}
      {swapSheet && (
        <SwapIngredientSheet
          ingredient={swapSheet.ing}
          onClose={() => setSwapSheet(null)}
          onConfirm={(replacement, note) => confirmSwap(swapSheet.index, replacement, note)}
        />
      )}

      {/* Rate sheet */}
      {rateSheet && (
        <div className="absolute inset-0 z-50 flex flex-col justify-end" style={{ background: "rgba(43,36,32,0.45)", backdropFilter: "blur(4px)" }}>
          <div className="bg-[#FDF8F3] rounded-t-[28px] px-6 pt-5 pb-10 sheet-enter">
            <div className="w-10 h-1 bg-[rgba(43,36,32,0.15)] rounded-full mx-auto mb-5" />
            <h3 className="text-[#2B2420] text-lg text-center mb-1" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Rate this Recipe</h3>
            {rating && (
              <p className="text-[#9C8F8A] text-[13px] text-center mb-6" style={{ fontFamily: "Outfit, sans-serif" }}>
                Currently {rating.average.toFixed(1)} · {rating.count} ratings
              </p>
            )}
            <div className="flex justify-center mb-8">
              <StarPicker value={myRating} onChange={setMyRating} size={40} />
            </div>
            {myRating > 0 && (
              <p className="text-center text-[#C8920A] text-sm font-semibold mb-4" style={{ fontFamily: "Outfit, sans-serif" }}>
                {["", "Not great", "Needs work", "It was okay", "Pretty good", "Absolutely loved it"][myRating]}
              </p>
            )}
            <button
              onClick={() => {
                if (myRating > 0) { onRate?.(myRating); }
                setRateSheet(false);
              }}
              disabled={myRating === 0}
              className="w-full py-3.5 rounded-2xl text-sm font-semibold transition-all"
              style={{
                fontFamily: "Outfit, sans-serif",
                background: myRating > 0 ? "#C8920A" : "rgba(43,36,32,0.08)",
                color: myRating > 0 ? "white" : "#9C8F8A",
              }}
            >
              {myRating > 0 ? "Submit Rating" : "Tap a star to rate"}
            </button>
            <button onClick={() => setRateSheet(false)} className="w-full mt-3 py-2 text-[#9C8F8A] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Step Illustration ───────────────────────────────────────────────────────

function StepIllustration({ action, stepKey }: { action: StepAction; stepKey: number }) {
  // stepKey change triggers re-mount → re-runs drop-bounce CSS animation
  return (
    <div key={stepKey} className="flex flex-col items-center gap-2 mb-5">
      <div className="anim-drop-bounce relative w-24 h-20 flex items-end justify-center">
        {action === "boil" && <BoilIllustration />}
        {action === "chop" && <ChopIllustration />}
        {action === "heat" && <HeatIllustration />}
        {action === "saute" && <SauteIllustration />}
        {action === "tomato" && <TomatoIllustration />}
        {action === "simmer" && <SimmerIllustration />}
        {action === "pasta" && <PastaIllustration />}
        {action === "toss" && <TossIllustration />}
      </div>
      {/* Prototype annotation */}
      <div className="flex items-center gap-1.5 px-3 py-1 rounded-full border border-dashed border-[rgba(138,155,110,0.5)] bg-[rgba(138,155,110,0.08)]">
        <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
          <circle cx="5" cy="5" r="4" stroke="#8A9B6E" strokeWidth="1.2" />
          <path d="M5 3v2.5l1.5 1.5" stroke="#8A9B6E" strokeWidth="1.2" strokeLinecap="round" />
        </svg>
        <span className="text-[10px] font-medium text-[#8A9B6E]" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.03em" }}>
          micro-interaction · animated
        </span>
      </div>
    </div>
  );
}

/* — Individual illustration SVGs — */

function BoilIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Steam wisps */}
      <path className="anim-steam1" d="M26 28 Q28 22 26 16" stroke="rgba(253,248,243,0.55)" strokeWidth="2.5" strokeLinecap="round" style={{ transformOrigin: "26px 28px" }} />
      <path className="anim-steam2" d="M36 26 Q38 20 36 14" stroke="rgba(253,248,243,0.45)" strokeWidth="2.5" strokeLinecap="round" style={{ transformOrigin: "36px 26px" }} />
      <path className="anim-steam1" d="M46 28 Q44 22 46 16" stroke="rgba(253,248,243,0.5)" strokeWidth="2.5" strokeLinecap="round" style={{ transformOrigin: "46px 28px", animationDelay: "0.8s" }} />
      {/* Pot body */}
      <rect x="14" y="36" width="44" height="26" rx="8" fill="#D9713C" fillOpacity="0.25" stroke="#D9713C" strokeWidth="2" />
      {/* Pot lid */}
      <rect x="12" y="30" width="48" height="8" rx="4" fill="#D9713C" fillOpacity="0.35" stroke="#D9713C" strokeWidth="1.8" />
      <rect x="30" y="26" width="12" height="6" rx="3" fill="#D9713C" fillOpacity="0.5" stroke="#D9713C" strokeWidth="1.6" />
      {/* Handles */}
      <path d="M14 44 Q6 44 6 50 Q6 56 14 56" stroke="#D9713C" strokeWidth="2" fill="none" strokeLinecap="round" />
      <path d="M58 44 Q66 44 66 50 Q66 56 58 56" stroke="#D9713C" strokeWidth="2" fill="none" strokeLinecap="round" />
      {/* Bubbles inside */}
      <circle className="anim-bubble"  cx="26" cy="52" r="3" fill="#D9713C" fillOpacity="0.4" />
      <circle className="anim-bubble2" cx="36" cy="50" r="2.5" fill="#D9713C" fillOpacity="0.4" />
      <circle className="anim-bubble3" cx="46" cy="53" r="2" fill="#D9713C" fillOpacity="0.4" />
    </svg>
  );
}

function ChopIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Garlic bulb */}
      <ellipse cx="36" cy="52" rx="14" ry="10" fill="#FDF8F3" stroke="#D9713C" strokeWidth="1.8" />
      <path d="M36 42 Q40 36 36 30 Q32 36 36 42Z" fill="#FDF8F3" stroke="#D9713C" strokeWidth="1.6" />
      <path d="M36 42 Q44 38 46 32 Q40 32 36 42Z" fill="rgba(253,248,243,0.7)" stroke="#D9713C" strokeWidth="1.4" />
      <path d="M36 42 Q28 38 26 32 Q32 32 36 42Z" fill="rgba(253,248,243,0.7)" stroke="#D9713C" strokeWidth="1.4" />
      {/* Clove lines */}
      <path d="M29 50 Q33 46 36 50" stroke="#D9713C" strokeWidth="1.2" strokeLinecap="round" fill="none" />
      <path d="M36 50 Q39 46 43 50" stroke="#D9713C" strokeWidth="1.2" strokeLinecap="round" fill="none" />
      {/* Knife */}
      <rect x="46" y="26" width="4" height="28" rx="1" fill="rgba(253,248,243,0.2)" stroke="rgba(253,248,243,0.6)" strokeWidth="1.4" />
      <path d="M46 26 L62 30 L62 50 L46 54Z" fill="rgba(253,248,243,0.15)" stroke="rgba(253,248,243,0.55)" strokeWidth="1.4" />
      <path d="M50 26 L50 54" stroke="rgba(253,248,243,0.25)" strokeWidth="0.8" />
      {/* Motion lines */}
      <path d="M40 18 L42 22" stroke="#8A9B6E" strokeWidth="1.5" strokeLinecap="round" opacity="0.7" />
      <path d="M46 16 L48 20" stroke="#8A9B6E" strokeWidth="1.5" strokeLinecap="round" opacity="0.5" />
      <path d="M52 20 L54 24" stroke="#8A9B6E" strokeWidth="1.5" strokeLinecap="round" opacity="0.6" />
    </svg>
  );
}

function HeatIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Skillet */}
      <ellipse cx="36" cy="56" rx="22" ry="7" fill="#D9713C" fillOpacity="0.18" stroke="#D9713C" strokeWidth="1.8" />
      <rect x="14" y="44" width="44" height="14" rx="7" fill="#D9713C" fillOpacity="0.2" stroke="#D9713C" strokeWidth="1.8" />
      {/* Handle */}
      <path d="M58 51 L68 51" stroke="#D9713C" strokeWidth="3" strokeLinecap="round" />
      {/* Oil shimmer drops */}
      <ellipse className="anim-oil" cx="28" cy="50" rx="4" ry="2.5" fill="#D9713C" fillOpacity="0.35" style={{ animationDelay: "0s" }} />
      <ellipse className="anim-oil" cx="40" cy="49" rx="3" ry="2" fill="#D9713C" fillOpacity="0.3" style={{ animationDelay: "0.4s" }} />
      <ellipse className="anim-oil" cx="32" cy="53" rx="2" ry="1.5" fill="#D9713C" fillOpacity="0.25" style={{ animationDelay: "0.7s" }} />
      {/* Flame */}
      <path d="M28 58 Q26 52 30 46 Q28 50 32 46 Q30 54 34 50 Q34 56 28 58Z" fill="#D9713C" fillOpacity="0.5" />
      <path d="M36 58 Q34 52 38 44 Q36 50 40 44 Q38 54 42 48 Q42 56 36 58Z" fill="#D9713C" fillOpacity="0.4" />
      <path d="M44 58 Q42 54 46 48 Q44 52 48 48 Q46 56 44 58Z" fill="#D9713C" fillOpacity="0.35" />
    </svg>
  );
}

function SauteIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Pan */}
      <ellipse cx="34" cy="54" rx="20" ry="6" fill="#D9713C" fillOpacity="0.18" stroke="#D9713C" strokeWidth="1.8" />
      <rect x="14" y="43" width="40" height="13" rx="6.5" fill="#D9713C" fillOpacity="0.15" stroke="#D9713C" strokeWidth="1.8" />
      <path d="M54 49 L66 47" stroke="#D9713C" strokeWidth="3" strokeLinecap="round" />
      {/* Spoon — stir animation */}
      <g className="anim-stir" style={{ transformOrigin: "36px 54px" }}>
        <rect x="34" y="22" width="4" height="32" rx="2" fill="rgba(253,248,243,0.5)" stroke="rgba(253,248,243,0.7)" strokeWidth="1.4" />
        <ellipse cx="36" cy="22" rx="5" ry="7" fill="rgba(253,248,243,0.3)" stroke="rgba(253,248,243,0.65)" strokeWidth="1.4" />
      </g>
      {/* Garlic bits */}
      <ellipse cx="26" cy="50" rx="3" ry="2" fill="#8A9B6E" fillOpacity="0.6" />
      <ellipse cx="36" cy="48" rx="2.5" ry="1.8" fill="#8A9B6E" fillOpacity="0.5" />
      <ellipse cx="44" cy="51" rx="3" ry="2" fill="#8A9B6E" fillOpacity="0.55" />
      {/* Steam */}
      <path className="anim-steam1" d="M26 42 Q28 37 26 32" stroke="rgba(253,248,243,0.4)" strokeWidth="2" strokeLinecap="round" style={{ transformOrigin: "26px 42px" }} />
      <path className="anim-steam2" d="M36 40 Q38 35 36 30" stroke="rgba(253,248,243,0.35)" strokeWidth="2" strokeLinecap="round" style={{ transformOrigin: "36px 40px" }} />
    </svg>
  );
}

function TomatoIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Drop trajectory */}
      <path d="M36 8 L36 36" stroke="rgba(217,113,60,0.2)" strokeWidth="1.5" strokeDasharray="3 3" />
      {/* Tomato body */}
      <circle cx="36" cy="46" r="18" fill="#D9713C" fillOpacity="0.25" stroke="#D9713C" strokeWidth="2" />
      <circle cx="36" cy="46" r="14" fill="#D9713C" fillOpacity="0.2" />
      {/* Highlight */}
      <ellipse cx="30" cy="40" rx="5" ry="3.5" fill="white" fillOpacity="0.3" transform="rotate(-20 30 40)" />
      {/* Stem */}
      <path d="M36 28 Q34 22 30 20" stroke="#8A9B6E" strokeWidth="2" strokeLinecap="round" fill="none" />
      <path d="M36 28 Q38 22 42 20" stroke="#8A9B6E" strokeWidth="2" strokeLinecap="round" fill="none" />
      <path d="M36 28 Q36 22 36 18" stroke="#8A9B6E" strokeWidth="2" strokeLinecap="round" />
      {/* Segments */}
      <path d="M36 30 Q42 40 36 50" stroke="#D9713C" strokeWidth="1.2" fillOpacity="0" strokeOpacity="0.4" />
      <path d="M36 30 Q30 40 36 50" stroke="#D9713C" strokeWidth="1.2" fillOpacity="0" strokeOpacity="0.4" />
    </svg>
  );
}

function SimmerIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Pot */}
      <rect x="12" y="38" width="48" height="24" rx="8" fill="#D9713C" fillOpacity="0.2" stroke="#D9713C" strokeWidth="2" />
      <rect x="10" y="32" width="52" height="8" rx="4" fill="#D9713C" fillOpacity="0.28" stroke="#D9713C" strokeWidth="1.8" />
      <rect x="28" y="28" width="16" height="6" rx="3" fill="#D9713C" fillOpacity="0.4" stroke="#D9713C" strokeWidth="1.6" />
      <path d="M12 46 Q4 46 4 52 Q4 58 12 58" stroke="#D9713C" strokeWidth="2" fill="none" strokeLinecap="round" />
      <path d="M60 46 Q68 46 68 52 Q68 58 60 58" stroke="#D9713C" strokeWidth="2" fill="none" strokeLinecap="round" />
      {/* Bubbles rising */}
      <circle className="anim-bubble"  cx="22" cy="54" r="3.5" fill="rgba(253,248,243,0.35)" stroke="#D9713C" strokeWidth="1.2" />
      <circle className="anim-bubble2" cx="36" cy="50" r="4" fill="rgba(253,248,243,0.3)" stroke="#D9713C" strokeWidth="1.2" />
      <circle className="anim-bubble3" cx="50" cy="55" r="3" fill="rgba(253,248,243,0.35)" stroke="#D9713C" strokeWidth="1.2" />
      {/* Steam */}
      <path className="anim-steam1" d="M22 30 Q24 24 22 18" stroke="rgba(253,248,243,0.5)" strokeWidth="2.2" strokeLinecap="round" style={{ transformOrigin: "22px 30px" }} />
      <path className="anim-steam2" d="M36 28 Q38 22 36 16" stroke="rgba(253,248,243,0.45)" strokeWidth="2.2" strokeLinecap="round" style={{ transformOrigin: "36px 28px" }} />
      <path className="anim-steam1" d="M50 30 Q48 24 50 18" stroke="rgba(253,248,243,0.4)" strokeWidth="2.2" strokeLinecap="round" style={{ transformOrigin: "50px 30px", animationDelay: "0.7s" }} />
    </svg>
  );
}

function PastaIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Spaghetti strands dropping */}
      <path d="M24 8 Q26 20 24 32 Q22 44 24 56" stroke="rgba(253,248,243,0.6)" strokeWidth="1.8" strokeLinecap="round" fill="none" />
      <path d="M30 6 Q32 18 30 30 Q28 42 30 56" stroke="rgba(253,248,243,0.55)" strokeWidth="1.8" strokeLinecap="round" fill="none" style={{ animationDelay: "0.1s" }} />
      <path d="M36 8 Q38 20 36 32 Q34 44 36 56" stroke="rgba(253,248,243,0.65)" strokeWidth="2" strokeLinecap="round" fill="none" />
      <path d="M42 6 Q44 18 42 30 Q40 42 42 56" stroke="rgba(253,248,243,0.5)" strokeWidth="1.8" strokeLinecap="round" fill="none" />
      <path d="M48 8 Q50 20 48 32 Q46 44 48 56" stroke="rgba(253,248,243,0.55)" strokeWidth="1.8" strokeLinecap="round" fill="none" />
      {/* Water surface */}
      <ellipse cx="36" cy="56" rx="20" ry="5" fill="#D9713C" fillOpacity="0.25" stroke="#D9713C" strokeWidth="1.5" />
      <circle className="anim-bubble"  cx="28" cy="54" r="2.5" fill="#D9713C" fillOpacity="0.3" />
      <circle className="anim-bubble2" cx="40" cy="52" r="2" fill="#D9713C" fillOpacity="0.3" />
    </svg>
  );
}

function TossIllustration() {
  return (
    <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
      {/* Pan */}
      <ellipse cx="32" cy="56" rx="18" ry="5.5" fill="#D9713C" fillOpacity="0.18" stroke="#D9713C" strokeWidth="1.8" />
      <rect x="14" y="45" width="36" height="13" rx="6.5" fill="#D9713C" fillOpacity="0.15" stroke="#D9713C" strokeWidth="1.8" />
      <path d="M50 52 L62 48" stroke="#D9713C" strokeWidth="3" strokeLinecap="round" />
      {/* Pasta arcing in the air */}
      <g className="anim-toss">
        <path d="M24 44 Q28 32 36 36 Q44 40 40 44" stroke="rgba(253,248,243,0.65)" strokeWidth="2" strokeLinecap="round" fill="none" />
        <path d="M28 42 Q32 28 40 32" stroke="rgba(253,248,243,0.5)" strokeWidth="2" strokeLinecap="round" fill="none" />
        {/* Sauce drops */}
        <circle cx="36" cy="28" r="3" fill="#D9713C" fillOpacity="0.5" />
        <circle cx="42" cy="32" r="2" fill="#D9713C" fillOpacity="0.4" />
        <circle cx="30" cy="34" r="1.8" fill="#D9713C" fillOpacity="0.35" />
      </g>
      {/* Steam */}
      <path className="anim-steam1" d="M24 42 Q26 37 24 32" stroke="rgba(253,248,243,0.4)" strokeWidth="2" strokeLinecap="round" style={{ transformOrigin: "24px 42px" }} />
    </svg>
  );
}

// ─── Screen: Cook Mode ────────────────────────────────────────────────────────

function CookModeScreen({
  onBack,
  onAskAI,
  onRate,
}: {
  onBack: () => void;
  onAskAI: () => void;
  onRate?: (stars: number) => void;
}) {
  const [stepIndex, setStepIndex] = useState(0);
  const [timeLeft, setTimeLeft] = useState<number | null>(null);
  const [timerRunning, setTimerRunning] = useState(false);
  const [reflectionSheet, setReflectionSheet] = useState(false);
  const [reflectionRating, setReflectionRating] = useState(0);
  const [issueText, setIssueText] = useState("");

  const step = COOK_STEPS[stepIndex];
  const totalSteps = COOK_STEPS.length;

  useEffect(() => {
    if (step.timer) {
      setTimeLeft(step.timer);
      setTimerRunning(false);
    } else {
      setTimeLeft(null);
      setTimerRunning(false);
    }
  }, [stepIndex]);

  useEffect(() => {
    if (!timerRunning || timeLeft === null) return;
    if (timeLeft === 0) {
      setTimerRunning(false);
      return;
    }
    const t = setTimeout(() => setTimeLeft((n) => (n ?? 1) - 1), 1000);
    return () => clearTimeout(t);
  }, [timerRunning, timeLeft]);

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${m}:${sec.toString().padStart(2, "0")}`;
  };

  const timerMax = step.timer ?? 1;
  const timerProgress = timeLeft !== null ? timeLeft / timerMax : 0;
  const circumference = 2 * Math.PI * 42;
  const dashOffset = circumference * (1 - timerProgress);

  return (
    <div className="absolute inset-0 bg-[#2B2420] flex flex-col">
      {/* Progress bar header */}
      <div className="pt-14 px-5 pb-4">
        <div className="flex items-center justify-between mb-3">
          <button onClick={onBack} className="p-1">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path
                d="M15 18l-6-6 6-6"
                stroke="rgba(253,248,243,0.7)"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
          <span
            className="text-[rgba(253,248,243,0.6)] text-sm"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            Step {stepIndex + 1} of {totalSteps}
          </span>
          <div className="w-8" />
        </div>
        {/* Progress bar */}
        <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
          <div
            className="h-full bg-[#8A9B6E] rounded-full transition-all duration-500"
            style={{ width: `${((stepIndex + 1) / totalSteps) * 100}%` }}
          />
        </div>
      </div>

      {/* Step content */}
      <div className="flex-1 flex flex-col justify-center px-6">
        {/* Animated micro-illustration — re-mounts on stepIndex change to replay drop-bounce */}
        <StepIllustration key={stepIndex} action={step.action} stepKey={stepIndex} />

        <div className="mb-6">
          <div className="w-10 h-10 rounded-full bg-[#D9713C]/20 flex items-center justify-center mb-4">
            <span
              className="text-[#D9713C] font-bold"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {stepIndex + 1}
            </span>
          </div>
          <p
            className="text-[#FDF8F3] text-[22px] leading-relaxed"
            style={{ fontFamily: "Lora, serif", fontWeight: 500 }}
          >
            {step.text}
          </p>
        </div>

        {/* Timer */}
        {timeLeft !== null && (
          <div className="flex flex-col items-center py-6">
            <div className="relative w-[100px] h-[100px]">
              <svg width="100" height="100" viewBox="0 0 100 100">
                <circle
                  cx="50"
                  cy="50"
                  r="42"
                  fill="none"
                  stroke="rgba(255,255,255,0.1)"
                  strokeWidth="6"
                />
                <circle
                  cx="50"
                  cy="50"
                  r="42"
                  fill="none"
                  stroke="#D9713C"
                  strokeWidth="6"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  strokeDashoffset={dashOffset}
                  transform="rotate(-90 50 50)"
                  style={{ transition: "stroke-dashoffset 1s linear" }}
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <span
                  className="text-[#FDF8F3] text-xl font-bold"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {formatTime(timeLeft)}
                </span>
              </div>
            </div>
            <button
              onClick={() => setTimerRunning(!timerRunning)}
              className="mt-3 text-[#D9713C] text-sm font-medium"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {timerRunning ? "Pause" : timeLeft < timerMax ? "Resume" : "Start Timer"}
            </button>
          </div>
        )}
      </div>

      {/* Navigation buttons */}
      <div className="px-5 pb-10 flex gap-3">
        <button
          onClick={() => setStepIndex(Math.max(0, stepIndex - 1))}
          disabled={stepIndex === 0}
          className="flex-1 py-4 rounded-2xl bg-white/10 text-[#FDF8F3] font-semibold disabled:opacity-30 active:bg-white/20 transition-colors"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          ← Previous
        </button>
        {stepIndex < totalSteps - 1 ? (
          <button
            onClick={() => setStepIndex(stepIndex + 1)}
            className="flex-[2] py-4 rounded-2xl bg-[#D9713C] text-white font-semibold shadow-[0_4px_16px_rgba(217,113,60,0.3)] active:opacity-80 transition-opacity"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            Next Step →
          </button>
        ) : (
          <button
            onClick={() => setReflectionSheet(true)}
            className="flex-[2] py-4 rounded-2xl text-white font-semibold shadow-[0_4px_16px_rgba(200,146,10,0.35)] active:opacity-80 transition-opacity"
            style={{ fontFamily: "Outfit, sans-serif", background: "#C8920A" }}
          >
            Finish Cooking ✓
          </button>
        )}
      </div>

      {/* Floating AI button */}
      <button
        onClick={onAskAI}
        className="glass-button absolute bottom-32 right-5 w-14 h-14 rounded-full shadow-[0_4px_20px_rgba(0,0,0,0.3)] flex items-center justify-center active:scale-95 transition-transform"
      >
        <span className="text-[#D9713C] text-xl">✦</span>
      </button>

      {/* Post-Cook Reflection sheet */}
      {reflectionSheet && (
        <div className="absolute inset-0 z-50 flex flex-col justify-end" style={{ background: "rgba(43,36,32,0.6)", backdropFilter: "blur(6px)" }}>
          <div className="bg-[#FDF8F3] rounded-t-[28px] px-6 pt-5 pb-10 sheet-enter">
            <div className="w-10 h-1 bg-[rgba(43,36,32,0.15)] rounded-full mx-auto mb-5" />
            <div className="text-center mb-2">
              <span className="text-3xl">🍽</span>
            </div>
            <h3 className="text-[#2B2420] text-xl text-center mb-1" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>
              How did it turn out?
            </h3>
            <p className="text-[#9C8F8A] text-[13px] text-center mb-6" style={{ fontFamily: "Outfit, sans-serif" }}>
              Your rating helps the community
            </p>
            <div className="flex justify-center mb-3">
              <StarPicker value={reflectionRating} onChange={setReflectionRating} size={44} />
            </div>
            {reflectionRating > 0 && (
              <p className="text-center text-[#C8920A] text-sm font-semibold mb-5" style={{ fontFamily: "Outfit, sans-serif" }}>
                {["", "Not great", "Needs work", "It was okay", "Pretty good", "Absolutely loved it"][reflectionRating]}
              </p>
            )}
            {reflectionRating > 0 && reflectionRating <= 3 && (
              <div className="mb-5">
                <p className="text-[#5C4F4A] text-[13px] font-medium mb-2" style={{ fontFamily: "Outfit, sans-serif" }}>
                  What went wrong? (optional)
                </p>
                <textarea
                  value={issueText}
                  onChange={(e) => setIssueText(e.target.value)}
                  placeholder="Describe the issue — our AI will note it for future improvements"
                  rows={3}
                  className="w-full px-3 py-2.5 rounded-xl text-[13px] text-[#2B2420] resize-none border outline-none focus:border-[#C8920A]"
                  style={{ fontFamily: "Outfit, sans-serif", background: "#F5EFE8", borderColor: "rgba(43,36,32,0.12)" }}
                />
              </div>
            )}
            <button
              onClick={() => {
                if (reflectionRating > 0) onRate?.(reflectionRating);
                setReflectionSheet(false);
                onBack();
              }}
              className="w-full py-3.5 rounded-2xl text-sm font-semibold transition-all mb-3"
              style={{
                fontFamily: "Outfit, sans-serif",
                background: reflectionRating > 0 ? "#C8920A" : "#D9713C",
                color: "white",
              }}
            >
              {reflectionRating > 0 ? "Submit & Finish" : "Finish without rating"}
            </button>
            {reflectionRating === 0 && (
              <button onClick={() => { setReflectionSheet(false); onBack(); }} className="w-full py-2 text-[#9C8F8A] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>
                Skip
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Screen: Ask AI Overlay ───────────────────────────────────────────────────

function AskAIOverlay({ onClose, currentStep }: { onClose: () => void; currentStep: string }) {
  const [messages, setMessages] = useState(AI_MESSAGES);
  const [input, setInput] = useState("");
  const suggestions = [
    "Substitute an ingredient",
    "I'm running late",
    "This doesn't look right",
  ];

  const send = (text: string) => {
    if (!text.trim()) return;
    setMessages([
      ...messages,
      { role: "user", text },
      {
        role: "ai",
        text: "That's a great question! Based on your current step, I'd recommend adjusting the heat to medium-low and adding a splash of pasta water if things are getting too thick. You're doing great — the key is patience!",
      },
    ]);
    setInput("");
  };

  return (
    <div className="absolute inset-0 flex flex-col justify-end">
      <button
        onClick={onClose}
        className="absolute inset-0 bg-black/40"
      />
      <div
        className="relative bg-[#FDF8F3] rounded-t-[28px] flex flex-col shadow-[0_-8px_40px_rgba(0,0,0,0.2)] sheet-enter"
        style={{ maxHeight: "80%" }}
      >
        {/* Drag handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 rounded-full bg-[rgba(43,36,32,0.15)]" />
        </div>

        {/* Context label */}
        <div className="px-5 pb-3 flex items-center justify-between">
          <div>
            <h2
              className="text-[#2B2420] text-lg"
              style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
            >
              Ask AI
            </h2>
            <span
              className="inline-flex items-center gap-1 bg-[#8A9B6E]/15 text-[#8A9B6E] text-[11px] font-semibold px-3 py-1 rounded-full mt-1"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              📍 {currentStep}
            </span>
          </div>
          <button onClick={onClose} className="p-2">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path
                d="M18 6L6 18M6 6l12 12"
                stroke="#9C8F8A"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </svg>
          </button>
        </div>

        {/* Chat messages */}
        <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-2 space-y-3" style={{ minHeight: 0, maxHeight: 280 }}>
          {messages.map((msg, i) => (
            <div
              key={i}
              className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
            >
              <div
                className={`max-w-[80%] px-4 py-3 rounded-[18px] text-sm leading-relaxed ${
                  msg.role === "user"
                    ? "bg-[#D9713C] text-white rounded-br-[6px]"
                    : "bg-white border border-[rgba(43,36,32,0.1)] text-[#2B2420] rounded-bl-[6px]"
                }`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {msg.text}
              </div>
            </div>
          ))}
        </div>

        {/* Suggested chips */}
        <div className="px-5 pt-2 pb-2">
          <div className="flex gap-2 overflow-x-auto no-scrollbar">
            {suggestions.map((s) => (
              <button
                key={s}
                onClick={() => send(s)}
                className="flex-shrink-0 bg-white border border-[rgba(43,36,32,0.1)] text-[#5C4F4A] text-[12px] font-medium px-3 py-1.5 rounded-full"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {s}
              </button>
            ))}
          </div>
        </div>

        {/* Input */}
        <div className="px-5 pb-8 pt-2 flex gap-2">
          <input
            type="text"
            placeholder="Ask anything about this step..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && send(input)}
            className="flex-1 bg-white border border-[rgba(43,36,32,0.1)] rounded-full px-4 py-3 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C]"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
          <button
            onClick={() => send(input)}
            className="w-11 h-11 rounded-full bg-[#D9713C] flex items-center justify-center flex-shrink-0 shadow-[0_2px_10px_rgba(217,113,60,0.3)]"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path
                d="M22 2L11 13M22 2L15 22l-4-9-9-4 20-7z"
                stroke="white"
                strokeWidth="1.75"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Screen: Saved Recipes ────────────────────────────────────────────────────

function SavedScreen({
  onRecipe,
  activeTab,
  onTab,
  ratings,
}: {
  onRecipe: (r: Recipe) => void;
  activeTab: Tab;
  onTab: (t: Tab) => void;
  ratings: Record<string, RecipeRatingData>;
}) {
  const [view, setView] = useState<"grid" | "list">("grid");
  const saved = RECIPES.slice(0, 4);

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      <div className="pt-14 px-5 pb-4">
        <div className="flex items-center justify-between mb-4">
          <h1
            className="text-[#2B2420] text-2xl"
            style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
          >
            Saved Recipes
          </h1>
          <div className="flex bg-white rounded-xl p-0.5 border border-[rgba(43,36,32,0.08)]">
            {(["grid", "list"] as const).map((v) => (
              <button
                key={v}
                onClick={() => setView(v)}
                className={`px-3 py-1.5 rounded-[10px] transition-all ${view === v ? "bg-[#D9713C] text-white" : "text-[#9C8F8A]"}`}
              >
                {v === "grid" ? (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <rect x="3" y="3" width="8" height="8" rx="1.5" stroke="currentColor" strokeWidth="2" />
                    <rect x="13" y="3" width="8" height="8" rx="1.5" stroke="currentColor" strokeWidth="2" />
                    <rect x="3" y="13" width="8" height="8" rx="1.5" stroke="currentColor" strokeWidth="2" />
                    <rect x="13" y="13" width="8" height="8" rx="1.5" stroke="currentColor" strokeWidth="2" />
                  </svg>
                ) : (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <path d="M9 6h11M9 12h11M9 18h11M4 6h.01M4 12h.01M4 18h.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                  </svg>
                )}
              </button>
            ))}
          </div>
        </div>

        <p
          className="text-[#9C8F8A] text-sm"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          {saved.length} recipes saved
        </p>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-24">
        {/* Section header */}
        <div className="mb-3">
          <h2
            className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-widest"
            style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}
          >
            Recently Saved
          </h2>
        </div>

        {view === "grid" ? (
          <div className="grid grid-cols-2 gap-3">
            {saved.map((r) => (
              <RecipeCard key={r.id} recipe={r} rating={ratings[r.id]} onTap={() => onRecipe(r)} />
            ))}
          </div>
        ) : (
          <div className="space-y-3">
            {saved.map((r) => (
              <button
                key={r.id}
                onClick={() => onRecipe(r)}
                className="w-full flex gap-3 bg-white rounded-2xl p-3 shadow-[0_1px_8px_rgba(43,36,32,0.07)] active:scale-[0.99] transition-transform"
              >
                <div className="w-20 h-20 rounded-xl overflow-hidden bg-[#E8DDD5] flex-shrink-0">
                  <img src={r.image} alt={r.title} className="w-full h-full object-cover" />
                </div>
                <div className="flex flex-col justify-center text-left">
                  <h3
                    className="text-[#2B2420] font-semibold text-sm leading-snug mb-1"
                    style={{ fontFamily: "Lora, serif" }}
                  >
                    {r.title}
                  </h3>
                  <p
                    className="text-[#9C8F8A] text-[12px]"
                    style={{ fontFamily: "Outfit, sans-serif" }}
                  >
                    {r.cuisine} · {r.time}
                  </p>
                  <DifficultyBadge level={r.difficulty} />
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      <TabBar active={activeTab} onSelect={onTab} />
    </div>
  );
}

// ─── Screen: Cook History ─────────────────────────────────────────────────────

function HistoryScreen({
  activeTab,
  onTab,
}: {
  activeTab: Tab;
  onTab: (t: Tab) => void;
}) {
  const [expanded, setExpanded] = useState<number | null>(null);

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      <div className="pt-14 px-5 pb-4">
        <h1
          className="text-[#2B2420] text-2xl"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          Cook History
        </h1>
        <p
          className="text-[#9C8F8A] text-sm mt-1"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          Your culinary journey
        </p>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-24">
        <div className="relative">
          {/* Timeline line */}
          <div className="absolute left-[52px] top-0 bottom-0 w-px bg-[rgba(138,155,110,0.2)]" />

          <div className="space-y-6">
            {HISTORY_ITEMS.map((item, i) => (
              <div key={i} className="flex gap-4">
                {/* Date marker */}
                <div className="flex-shrink-0 w-[52px] text-right">
                  <span
                    className="text-[11px] font-semibold text-[#8A9B6E] block pt-3.5"
                    style={{ fontFamily: "Outfit, sans-serif" }}
                  >
                    {item.date}
                  </span>
                  <div className="flex justify-end mt-1 mr-[-5px]">
                    <div className="w-2.5 h-2.5 rounded-full bg-[#8A9B6E] border-2 border-[#FDF8F3]" />
                  </div>
                </div>

                {/* Entry card */}
                <button
                  onClick={() => setExpanded(expanded === i ? null : i)}
                  className="flex-1 bg-white rounded-2xl shadow-[0_1px_8px_rgba(43,36,32,0.07)] overflow-hidden active:scale-[0.99] transition-transform"
                >
                  <div className="flex p-3 gap-3">
                    <div className="w-16 h-16 rounded-xl overflow-hidden bg-[#E8DDD5] flex-shrink-0">
                      <img
                        src={item.image}
                        alt={item.recipe}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="flex flex-col justify-center text-left flex-1">
                      <h3
                        className="text-[#2B2420] font-semibold text-sm"
                        style={{ fontFamily: "Lora, serif" }}
                      >
                        {item.recipe}
                      </h3>
                      <div className="mt-0.5 mb-0.5">
                        <UploaderAttribution uploader={item.uploader} size="sm" />
                      </div>
                      <p
                        className="text-[#9C8F8A] text-[11px] mt-0.5"
                        style={{ fontFamily: "Outfit, sans-serif" }}
                      >
                        Cooked · {item.date}
                      </p>
                      {item.tip && (
                        <span
                          className="inline-flex items-center gap-1 bg-[#D9713C]/10 text-[#D9713C] text-[10px] font-medium px-2 py-0.5 rounded-full mt-1.5"
                          style={{ fontFamily: "Outfit, sans-serif" }}
                        >
                          ✦ AI Tip
                        </span>
                      )}
                    </div>
                  </div>
                  {expanded === i && item.tip && (
                    <div className="px-4 pb-3 border-t border-[rgba(43,36,32,0.06)] pt-3">
                      <p
                        className="text-[#5C4F4A] text-sm"
                        style={{ fontFamily: "Outfit, sans-serif" }}
                      >
                        💬 {item.tip}
                      </p>
                    </div>
                  )}
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>

      <TabBar active={activeTab} onSelect={onTab} />
    </div>
  );
}

// ─── Screen: Profile ──────────────────────────────────────────────────────────

function ProfileScreen({
  activeTab,
  onTab,
  isAdmin,
  onAdmin,
  onLogout,
}: {
  activeTab: Tab;
  onTab: (t: Tab) => void;
  isAdmin: boolean;
  onAdmin: () => void;
  onLogout: () => void;
}) {
  const [diet, setDiet] = useState({
    vegetarian: false,
    vegan: false,
    "gluten-free": false,
    "dairy-free": false,
  });
  const [units, setUnits] = useState<"metric" | "imperial">("metric");
  const [cuisines, setCuisines] = useState(["Italian", "Japanese"]);
  const allCuisines = ["Italian", "Japanese", "Filipino", "Mexican", "Indian", "American"];

  const toggleCuisine = (c: string) => {
    setCuisines((prev) =>
      prev.includes(c) ? prev.filter((x) => x !== c) : [...prev, c],
    );
  };

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col overflow-y-auto no-scrollbar">
      {/* Header */}
      <div className="pt-14 px-5 pb-6">
        <h1
          className="text-[#2B2420] text-2xl mb-5"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          Profile
        </h1>
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#D9713C] to-[#B85A28] flex items-center justify-center shadow-[0_4px_16px_rgba(217,113,60,0.3)]">
            <span className="text-white text-2xl font-bold" style={{ fontFamily: "Lora, serif" }}>A</span>
          </div>
          <div>
            <h2
              className="text-[#2B2420] text-lg font-semibold"
              style={{ fontFamily: "Lora, serif" }}
            >
              Alex Rivera
            </h2>
            <p
              className="text-[#9C8F8A] text-sm"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              Home cook · 24 recipes cooked
            </p>
          </div>
        </div>
      </div>

      <div className="px-5 pb-32 space-y-6">
        {/* Dietary Preferences */}
        <div>
          <h3
            className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-widest mb-3"
            style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}
          >
            Dietary Preferences
          </h3>
          <div className="flex flex-wrap gap-2">
            {Object.keys(diet).map((d) => (
              <button
                key={d}
                onClick={() => setDiet({ ...diet, [d]: !diet[d as keyof typeof diet] })}
                className={`px-4 py-2 rounded-full text-sm font-medium border transition-all capitalize ${
                  diet[d as keyof typeof diet]
                    ? "bg-[#8A9B6E] text-white border-[#8A9B6E]"
                    : "bg-white text-[#5C4F4A] border-[rgba(43,36,32,0.12)]"
                }`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {d}
              </button>
            ))}
          </div>
        </div>

        {/* Favorite Cuisines */}
        <div>
          <h3
            className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-widest mb-3"
            style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}
          >
            Favorite Cuisines
          </h3>
          <div className="flex flex-wrap gap-2">
            {allCuisines.map((c) => (
              <button
                key={c}
                onClick={() => toggleCuisine(c)}
                className={`px-4 py-2 rounded-full text-sm font-medium border transition-all ${
                  cuisines.includes(c)
                    ? "bg-[#D9713C] text-white border-[#D9713C] shadow-[0_2px_8px_rgba(217,113,60,0.25)]"
                    : "bg-white text-[#5C4F4A] border-[rgba(43,36,32,0.12)]"
                }`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {c}
              </button>
            ))}
          </div>
        </div>

        {/* Units toggle */}
        <div className="bg-white rounded-2xl p-4 shadow-[0_1px_8px_rgba(43,36,32,0.07)]">
          <div className="flex items-center justify-between">
            <div>
              <p
                className="text-[#2B2420] text-sm font-semibold"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                Measurement Units
              </p>
              <p
                className="text-[#9C8F8A] text-xs mt-0.5"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                Used for all recipe quantities
              </p>
            </div>
            <div className="flex bg-[#F5EFE9] rounded-xl p-0.5">
              {(["metric", "imperial"] as const).map((u) => (
                <button
                  key={u}
                  onClick={() => setUnits(u)}
                  className={`px-3 py-1.5 rounded-[10px] text-sm font-medium capitalize transition-all ${
                    units === u ? "bg-white text-[#2B2420] shadow-sm" : "text-[#9C8F8A]"
                  }`}
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {u}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Settings list */}
        <div>
          <h3
            className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-widest mb-3"
            style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}
          >
            App Settings
          </h3>
          <div className="bg-white rounded-2xl shadow-[0_1px_8px_rgba(43,36,32,0.07)] divide-y divide-[rgba(43,36,32,0.06)]">
            {[
              { icon: "🔔", label: "Notifications", action: null },
              { icon: "ℹ️", label: "About CookAI", action: null },
              { icon: "⭐", label: "Rate the app", action: null },
            ].map((item) => (
              <button
                key={item.label}
                className="w-full flex items-center justify-between px-4 py-3.5 active:bg-[rgba(43,36,32,0.03)]"
              >
                <div className="flex items-center gap-3">
                  <span className="text-lg">{item.icon}</span>
                  <span className="text-[#2B2420] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>{item.label}</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M9 18l6-6-6-6" stroke="#C4B8B3" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            ))}
            {/* Admin entry — only shown for admin role */}
            {isAdmin && (
              <button
                onClick={onAdmin}
                className="w-full flex items-center justify-between px-4 py-3.5 active:bg-[rgba(43,36,32,0.03)]"
              >
                <div className="flex items-center gap-3">
                  <span className="text-lg">🛡️</span>
                  <div className="text-left">
                    <span className="text-[#2B2420] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>Admin Dashboard</span>
                    <span className="block text-[10px] font-semibold text-[#D9713C] uppercase tracking-wide" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Admin only</span>
                  </div>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M9 18l6-6-6-6" stroke="#C4B8B3" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            )}
          </div>
        </div>

        {/* Log out */}
        <button
          onClick={onLogout}
          className="w-full py-3.5 rounded-2xl border border-[rgba(217,113,60,0.3)] text-[#D9713C] text-sm font-semibold"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          Log Out
        </button>
      </div>

      <TabBar active={activeTab} onSelect={onTab} />
    </div>
  );
}

// ─── Screen: Splash ──────────────────────────────────────────────────────────

function SplashScreen({ onDone }: { onDone: () => void }) {
  useEffect(() => {
    const t = setTimeout(onDone, 2200);
    return () => clearTimeout(t);
  }, [onDone]);

  return (
    <div
      className="absolute inset-0 flex flex-col items-center justify-center bg-[#FDF8F3]"
      style={{ animation: "fadeIn 0.6s ease-out both" }}
    >
      <style>{`@keyframes fadeIn{from{opacity:0;transform:scale(0.9)}to{opacity:1;transform:scale(1)}}`}</style>
      {/* Logo mark */}
      <div
        className="w-24 h-24 rounded-[28px] bg-[#D9713C] flex items-center justify-center mb-5 shadow-[0_8px_32px_rgba(217,113,60,0.35)]"
        style={{ animation: "fadeIn 0.7s cubic-bezier(0.22,1,0.36,1) both" }}
      >
        <svg width="52" height="52" viewBox="0 0 52 52" fill="none">
          <path d="M10 38c0 3 2.4 5 5.3 5h21.4C39.6 43 42 41 42 38V26H10v12z" fill="white" fillOpacity="0.2" stroke="white" strokeWidth="2" />
          <path d="M10 26h32M17 26V16c0-1.5 1.2-2.7 2.7-2.7S22.4 14.5 22.4 16v2M26 26V12c0-1.5 1.2-2.7 2.7-2.7S31.4 10.5 31.4 12v14M35 26V16c0-1.5 1.2-2.7 2.7-2.7S40.4 14.5 40.4 16v10" stroke="white" strokeWidth="2" strokeLinecap="round" />
          {/* Sparkle */}
          <path d="M8 12l1.5 3L8 18l-1.5-3L8 12z" fill="white" fillOpacity="0.6" />
          <path d="M44 8l1 2 1-2-1-2-1 2z" fill="white" fillOpacity="0.5" />
        </svg>
      </div>
      {/* Wordmark */}
      <div style={{ animation: "fadeIn 0.8s 0.15s cubic-bezier(0.22,1,0.36,1) both" }}>
        <h1
          className="text-[#2B2420] text-[36px] tracking-tight"
          style={{ fontFamily: "Lora, serif", fontWeight: 700, letterSpacing: "-0.02em" }}
        >
          Cook<span className="text-[#D9713C]">AI</span>
        </h1>
      </div>
      <p
        className="text-[#9C8F8A] text-sm mt-2"
        style={{ fontFamily: "Outfit, sans-serif", animation: "fadeIn 0.8s 0.3s both" }}
      >
        Your AI-powered kitchen companion
      </p>
      {/* Subtle loading dot */}
      <div className="absolute bottom-16 flex gap-1.5" style={{ animation: "fadeIn 0.6s 0.8s both" }}>
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="w-1.5 h-1.5 rounded-full bg-[#D9713C]/40"
            style={{ animation: `simmerBubble 1.2s ease-in-out ${i * 0.2}s infinite` }}
          />
        ))}
      </div>
    </div>
  );
}

// ─── Screen: Login / Sign Up ──────────────────────────────────────────────────

function LoginScreen({
  onLogin,
  onGuest,
}: {
  onLogin: (isAdmin: boolean) => void;
  onGuest: () => void;
}) {
  const [mode, setMode] = useState<"login" | "signup">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPw, setShowPw] = useState(false);

  const submit = () => {
    if (!email || !password) return;
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      // Treat "admin@cookai.com" as an admin user for prototype purposes
      onLogin(email.toLowerCase().includes("admin"));
    }, 1200);
  };

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col overflow-y-auto no-scrollbar">
      {/* Warm decorative header band */}
      <div className="h-48 bg-gradient-to-b from-[#F2E6D8] to-[#FDF8F3] flex items-end justify-center pb-6">
        <div className="w-14 h-14 rounded-[16px] bg-[#D9713C] flex items-center justify-center shadow-[0_4px_16px_rgba(217,113,60,0.3)]">
          <svg width="30" height="30" viewBox="0 0 52 52" fill="none">
            <path d="M10 38c0 3 2.4 5 5.3 5h21.4C39.6 43 42 41 42 38V26H10v12z" fill="white" fillOpacity="0.25" stroke="white" strokeWidth="2.2" />
            <path d="M10 26h32M17 26V16c0-1.5 1.2-2.7 2.7-2.7S22.4 14.5 22.4 16v2M26 26V12c0-1.5 1.2-2.7 2.7-2.7S31.4 10.5 31.4 12v14M35 26V16c0-1.5 1.2-2.7 2.7-2.7S40.4 14.5 40.4 16v10" stroke="white" strokeWidth="2" strokeLinecap="round" />
          </svg>
        </div>
      </div>

      <div className="px-6 pb-10">
        <h1
          className="text-[#2B2420] text-2xl mb-1"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          {mode === "login" ? "Welcome back" : "Create account"}
        </h1>
        <p className="text-[#9C8F8A] text-sm mb-6" style={{ fontFamily: "Outfit, sans-serif" }}>
          {mode === "login" ? "Sign in to your CookAI account" : "Join the CookAI community"}
        </p>

        {/* Mode toggle */}
        <div className="flex bg-white rounded-2xl p-1 border border-[rgba(43,36,32,0.08)] mb-6">
          {(["login", "signup"] as const).map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all ${
                mode === m ? "bg-[#D9713C] text-white shadow-[0_2px_8px_rgba(217,113,60,0.25)]" : "text-[#9C8F8A]"
              }`}
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {m === "login" ? "Log In" : "Sign Up"}
            </button>
          ))}
        </div>

        <div className="space-y-4">
          {/* Name field — sign-up only */}
          {mode === "signup" && (
            <div>
              <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-1.5" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Your name</label>
              <input
                type="text"
                placeholder="Alex Rivera"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-white border border-[rgba(43,36,32,0.1)] rounded-2xl px-4 py-3.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
                style={{ fontFamily: "Outfit, sans-serif" }}
              />
            </div>
          )}

          {/* Email */}
          <div>
            <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-1.5" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Email</label>
            <input
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-white border border-[rgba(43,36,32,0.1)] rounded-2xl px-4 py-3.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
              style={{ fontFamily: "Outfit, sans-serif" }}
            />
          </div>

          {/* Password */}
          <div>
            <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-1.5" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Password</label>
            <div className="relative">
              <input
                type={showPw ? "text" : "password"}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && submit()}
                className="w-full bg-white border border-[rgba(43,36,32,0.1)] rounded-2xl px-4 py-3.5 pr-12 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
                style={{ fontFamily: "Outfit, sans-serif" }}
              />
              <button
                type="button"
                onClick={() => setShowPw(!showPw)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9C8F8A]"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                  {showPw
                    ? <><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" /><path d="M1 1l22 22" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" /></>
                    : <><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" strokeWidth="1.75" /><circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.75" /></>
                  }
                </svg>
              </button>
            </div>
          </div>

          {mode === "login" && (
            <div className="text-right">
              <button className="text-[#D9713C] text-[13px]" style={{ fontFamily: "Outfit, sans-serif" }}>Forgot password?</button>
            </div>
          )}
        </div>

        {/* Hint for prototype */}
        <div className="mt-4 px-3 py-2.5 rounded-xl bg-[rgba(138,155,110,0.08)] border border-[rgba(138,155,110,0.2)]">
          <p className="text-[11px] text-[#5C4F4A] leading-relaxed mb-2" style={{ fontFamily: "Outfit, sans-serif" }}>
            <span className="font-semibold text-[#8A9B6E]">Prototype tip:</span> Any password works. Tap a quick-fill below:
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => { setEmail("admin@cookai.com"); setPassword("admin123"); setMode("login"); }}
              className="flex-1 py-1.5 rounded-lg bg-[#D9713C]/15 text-[#D9713C] text-[11px] font-semibold border border-[rgba(217,113,60,0.2)] active:opacity-70 transition-opacity"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              🛡 Fill Admin
            </button>
            <button
              onClick={() => { setEmail("alex@example.com"); setPassword("hello123"); setMode("login"); }}
              className="flex-1 py-1.5 rounded-lg bg-[rgba(138,155,110,0.12)] text-[#8A9B6E] text-[11px] font-semibold border border-[rgba(138,155,110,0.2)] active:opacity-70 transition-opacity"
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              👤 Fill User
            </button>
          </div>
        </div>

        {/* Primary button */}
        <button
          onClick={submit}
          disabled={!email || !password || loading}
          className="w-full mt-5 bg-[#D9713C] text-white py-4 rounded-full text-base font-semibold shadow-[0_4px_16px_rgba(217,113,60,0.35)] disabled:opacity-50 active:scale-[0.98] transition-all flex items-center justify-center gap-2"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          {loading
            ? <><div className="w-4 h-4 rounded-full border-2 border-white/40 border-t-white" style={{ animation: "spin 0.8s linear infinite" }} /> Processing...</>
            : mode === "login" ? "Log In" : "Create Account"
          }
        </button>

        {/* Guest link */}
        <div className="mt-6 text-center">
          <button
            onClick={onGuest}
            className="text-[#9C8F8A] text-sm underline underline-offset-2"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            Continue as Guest
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Screen: Community / Discover ────────────────────────────────────────────

function CommunityScreen({
  onRecipe,
  onUpload,
  onUser,
  activeTab,
  onTab,
  onMessages,
  onNotifications,
  onAddNotification,
  ratings,
}: {
  onRecipe: (r: Recipe) => void;
  onUpload: () => void;
  onUser: (u: string) => void;
  activeTab: Tab;
  onTab: (t: Tab) => void;
  onMessages: () => void;
  onNotifications: () => void;
  onAddNotification?: (n: Omit<Notification, "id" | "read">) => void;
  ratings: Record<string, RecipeRatingData>;
}) {
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("All");
  const [likedIds, setLikedIds] = useState<Set<string>>(new Set());
  const [savedIds, setSavedIds] = useState<Set<string>>(new Set());
  const [likeCounts, setLikeCounts] = useState<Record<string, number>>(
    Object.fromEntries(COMMUNITY_RECIPES.map((r) => [r.id, r.likes]))
  );
  const filters = ["All", "Italian", "Japanese", "Thai", "Indian", "Mediterranean", "American"];

  const shown = COMMUNITY_RECIPES.filter((r) => {
    const matchSearch = !search || r.title.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === "All" || r.cuisine === filter;
    return matchSearch && matchFilter;
  });

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      <div className="pt-14 px-5 pb-3">
        <div className="flex items-center justify-between mb-1">
          <h1 className="text-[#2B2420] text-2xl" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Discover</h1>
          <div className="flex items-center gap-2">
            {/* Bell / Notifications */}
            <button
              onClick={onNotifications}
              className="relative w-9 h-9 rounded-full bg-white border border-[rgba(43,36,32,0.08)] flex items-center justify-center shadow-[0_1px_6px_rgba(43,36,32,0.07)] active:opacity-70 transition-opacity"
            >
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none">
                <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0" stroke="#5C4F4A" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#D9713C] text-white text-[9px] font-bold flex items-center justify-center" style={{ fontFamily: "Outfit, sans-serif" }}>3</span>
            </button>
            {/* Messages */}
            <button
              onClick={onMessages}
              className="relative w-9 h-9 rounded-full bg-white border border-[rgba(43,36,32,0.08)] flex items-center justify-center shadow-[0_1px_6px_rgba(43,36,32,0.07)] active:opacity-70 transition-opacity"
            >
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none">
                <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" stroke="#5C4F4A" strokeWidth="1.75" strokeLinejoin="round" />
              </svg>
              <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#D9713C] text-white text-[9px] font-bold flex items-center justify-center" style={{ fontFamily: "Outfit, sans-serif" }}>3</span>
            </button>
          </div>
        </div>
        <p className="text-[#9C8F8A] text-sm mb-4" style={{ fontFamily: "Outfit, sans-serif" }}>Recipes from the community</p>

        {/* Search */}
        <div className="relative mb-3">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
              <circle cx="11" cy="11" r="7" stroke="#9C8F8A" strokeWidth="2" />
              <path d="M16.5 16.5L21 21" stroke="#9C8F8A" strokeWidth="2" strokeLinecap="round" />
            </svg>
          </div>
          <input
            type="text"
            placeholder="Search community recipes..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white rounded-full pl-10 pr-4 py-3 text-sm text-[#2B2420] placeholder-[#C4B8B3] shadow-[0_1px_8px_rgba(43,36,32,0.07)] outline-none border border-[rgba(43,36,32,0.06)]"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
        </div>

        {/* Filter chips */}
        <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
          {filters.map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex-shrink-0 px-3.5 py-1.5 rounded-full text-[13px] font-medium border transition-all ${
                filter === f ? "bg-[#D9713C] text-white border-[#D9713C] shadow-[0_2px_8px_rgba(217,113,60,0.25)]" : "bg-white text-[#5C4F4A] border-[rgba(43,36,32,0.1)]"
              }`}
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Recipe list */}
      <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-28">
        <div className="space-y-4">
          {shown.map((recipe) => (
            // div instead of button — avoids nested <button> inside <button> (uploader row)
            <div
              key={recipe.id}
              onClick={() => onRecipe(recipe)}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => e.key === "Enter" && onRecipe(recipe)}
              className="w-full bg-white rounded-[20px] overflow-hidden shadow-[0_2px_16px_rgba(43,36,32,0.08)] active:scale-[0.99] transition-transform text-left cursor-pointer"
            >
              {/* Image */}
              <div className="relative bg-[#E8DDD5]" style={{ paddingTop: "52%" }}>
                <img src={recipe.image} alt={recipe.title} className="absolute inset-0 w-full h-full object-cover" />
              </div>
              {/* Card body */}
              <div className="p-4">
                <div className="flex items-start justify-between mb-2">
                  <h3 className="text-[#2B2420] font-semibold text-[15px] leading-snug flex-1 mr-2" style={{ fontFamily: "Lora, serif" }}>
                    {recipe.title}
                  </h3>
                  <DifficultyBadge level={recipe.difficulty} />
                </div>
                {/* Uploader row */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {/* Avatar + username — tappable to open user profile */}
                    <button
                      onClick={(e) => { e.stopPropagation(); onUser(recipe.uploader); }}
                      className="active:opacity-60 transition-opacity"
                    >
                      <UploaderAttribution uploader={recipe.uploader} avatarColor={recipe.avatarColor} size="sm" />
                    </button>
                    <span className="text-[#C4B8B3] text-[12px]">·</span>
                    <span className="text-[#9C8F8A] text-[12px]" style={{ fontFamily: "Outfit, sans-serif" }}>{recipe.time}</span>
                  </div>
                  {/* Stars */}
                  {ratings[recipe.id] && (
                    <StarRating average={ratings[recipe.id].average} count={ratings[recipe.id].count} size={13} />
                  )}
                  {/* Interactive like + save */}
                  <div className="flex items-center gap-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        const isNowLiked = !likedIds.has(recipe.id);
                        setLikedIds((prev) => { const s = new Set(prev); isNowLiked ? s.add(recipe.id) : s.delete(recipe.id); return s; });
                        setLikeCounts((prev) => ({ ...prev, [recipe.id]: (prev[recipe.id] ?? recipe.likes) + (isNowLiked ? 1 : -1) }));
                        if (isNowLiked) onAddNotification?.({ type: "liked", fromUser: "you", avatarColor: "#D9713C", recipeName: recipe.title, recipeId: recipe.id, timestamp: "Just now" });
                      }}
                      className="flex items-center gap-1 px-2 py-1 rounded-full transition-all active:scale-95"
                      style={{ background: likedIds.has(recipe.id) ? "rgba(217,113,60,0.10)" : "transparent" }}
                    >
                      <svg width="13" height="13" viewBox="0 0 24 24" fill={likedIds.has(recipe.id) ? "#D9713C" : "none"}>
                        <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" stroke={likedIds.has(recipe.id) ? "#D9713C" : "#9C8F8A"} strokeWidth="1.6" />
                      </svg>
                      <span className="text-[12px]" style={{ fontFamily: "Outfit, sans-serif", color: likedIds.has(recipe.id) ? "#D9713C" : "#9C8F8A" }}>{likeCounts[recipe.id] ?? recipe.likes}</span>
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setSavedIds((prev) => { const s = new Set(prev); s.has(recipe.id) ? s.delete(recipe.id) : s.add(recipe.id); return s; });
                      }}
                      className="flex items-center gap-1 px-2 py-1 rounded-full transition-all active:scale-95"
                      style={{ background: savedIds.has(recipe.id) ? "rgba(138,155,110,0.10)" : "transparent" }}
                    >
                      <svg width="13" height="13" viewBox="0 0 24 24" fill={savedIds.has(recipe.id) ? "#8A9B6E" : "none"}>
                        <path d="M5 3h14a1 1 0 011 1v17l-8-4-8 4V4a1 1 0 011-1z" stroke={savedIds.has(recipe.id) ? "#8A9B6E" : "#9C8F8A"} strokeWidth="1.6" />
                      </svg>
                      <span className="text-[12px]" style={{ fontFamily: "Outfit, sans-serif", color: savedIds.has(recipe.id) ? "#8A9B6E" : "#9C8F8A" }}>{recipe.saves}</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Floating Upload FAB */}
      <button
        onClick={onUpload}
        className="absolute bottom-24 right-5 flex items-center gap-2 bg-[#D9713C] text-white px-5 py-3.5 rounded-full shadow-[0_4px_20px_rgba(217,113,60,0.4)] active:scale-95 transition-transform z-10"
        style={{ fontFamily: "Outfit, sans-serif", fontWeight: 600, fontSize: 14 }}
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M12 5v14M5 12h14" stroke="white" strokeWidth="2.2" strokeLinecap="round" />
        </svg>
        Upload Recipe
      </button>

      <TabBar active={activeTab} onSelect={onTab} />
    </div>
  );
}

// ─── Screen: Upload Recipe ────────────────────────────────────────────────────

function UploadRecipeScreen({ onBack, onPublish }: { onBack: () => void; onPublish: () => void }) {
  const [title, setTitle] = useState("");
  const [cuisine, setCuisine] = useState("Italian");
  const [difficulty, setDifficulty] = useState<"Easy" | "Medium" | "Hard">("Easy");
  const [servings, setServings] = useState("2");
  const [ingredients, setIngredients] = useState(["", ""]);
  const [steps, setSteps] = useState([{ text: "", timer: "" }, { text: "", timer: "" }]);
  const [photoAdded] = useState(false);

  const addIngredient = () => setIngredients([...ingredients, ""]);
  const updateIngredient = (i: number, v: string) => { const a = [...ingredients]; a[i] = v; setIngredients(a); };
  const removeIngredient = (i: number) => setIngredients(ingredients.filter((_, idx) => idx !== i));

  const addStep = () => setSteps([...steps, { text: "", timer: "" }]);
  const updateStep = (i: number, field: "text" | "timer", v: string) => {
    const a = [...steps]; a[i] = { ...a[i], [field]: v }; setSteps(a);
  };
  const removeStep = (i: number) => setSteps(steps.filter((_, idx) => idx !== i));

  const cuisineOptions = ["Italian", "Japanese", "Filipino", "Mexican", "Indian", "American", "Thai", "Mediterranean", "Other"];

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-14 px-5 pb-4 flex items-center gap-3 border-b border-[rgba(43,36,32,0.07)]">
        <button onClick={onBack} className="p-1">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
        <h1 className="flex-1 text-[#2B2420] text-xl" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Upload Recipe</h1>
        <span className="text-[#9C8F8A] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>Draft</span>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-32 space-y-6 pt-5">
        {/* Photo picker */}
        <div>
          <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Recipe photo</label>
          <div className="w-full rounded-[20px] border-2 border-dashed border-[rgba(217,113,60,0.3)] bg-[rgba(217,113,60,0.04)] flex flex-col items-center justify-center py-10 gap-2">
            <div className="w-12 h-12 rounded-full bg-[#D9713C]/10 flex items-center justify-center">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                <rect x="3" y="3" width="18" height="18" rx="3" stroke="#D9713C" strokeWidth="1.8" />
                <circle cx="8.5" cy="8.5" r="1.5" stroke="#D9713C" strokeWidth="1.5" />
                <path d="M21 15l-5-5L5 21" stroke="#D9713C" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <span className="text-[#D9713C] text-sm font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>Tap to add photo</span>
            <span className="text-[#9C8F8A] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>JPG, PNG · max 10 MB</span>
          </div>
        </div>

        {/* Title */}
        <div>
          <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Recipe title</label>
          <input
            type="text"
            placeholder="e.g. My Grandma's Pasta"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full bg-white border border-[rgba(43,36,32,0.1)] rounded-2xl px-4 py-3.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
        </div>

        {/* Cuisine + Difficulty row */}
        <div className="flex gap-3">
          <div className="flex-1">
            <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Cuisine</label>
            <div className="relative">
              <select
                value={cuisine}
                onChange={(e) => setCuisine(e.target.value)}
                className="w-full bg-white border border-[rgba(43,36,32,0.1)] rounded-2xl px-4 py-3.5 text-sm text-[#2B2420] outline-none appearance-none focus:border-[#D9713C] transition-colors"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {cuisineOptions.map((c) => <option key={c}>{c}</option>)}
              </select>
              <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M6 9l6 6 6-6" stroke="#9C8F8A" strokeWidth="2" strokeLinecap="round" /></svg>
              </div>
            </div>
          </div>
          <div className="flex-1">
            <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Difficulty</label>
            <div className="flex bg-white rounded-2xl border border-[rgba(43,36,32,0.1)] p-1 gap-1">
              {(["Easy", "Medium", "Hard"] as const).map((d) => (
                <button
                  key={d}
                  onClick={() => setDifficulty(d)}
                  className={`flex-1 py-2 rounded-xl text-[12px] font-semibold transition-all ${difficulty === d ? "bg-[#D9713C] text-white" : "text-[#9C8F8A]"}`}
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  {d}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Servings */}
        <div>
          <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Servings</label>
          <div className="flex items-center gap-3">
            <button onClick={() => setServings(String(Math.max(1, Number(servings) - 1)))} className="w-10 h-10 rounded-full bg-white border border-[rgba(43,36,32,0.12)] flex items-center justify-center text-[#5C4F4A] text-lg font-light">−</button>
            <span className="text-[#2B2420] text-lg font-semibold w-8 text-center" style={{ fontFamily: "Outfit, sans-serif" }}>{servings}</span>
            <button onClick={() => setServings(String(Number(servings) + 1))} className="w-10 h-10 rounded-full bg-white border border-[rgba(43,36,32,0.12)] flex items-center justify-center text-[#D9713C] text-lg font-light">+</button>
          </div>
        </div>

        {/* Ingredients builder */}
        <div>
          <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Ingredients</label>
          <div className="space-y-2 mb-2">
            {ingredients.map((ing, i) => (
              <div key={i} className="flex items-center gap-2">
                <span className="w-5 h-5 rounded-full bg-[#D9713C]/15 flex-shrink-0 flex items-center justify-center text-[10px] font-bold text-[#D9713C]" style={{ fontFamily: "Outfit, sans-serif" }}>{i + 1}</span>
                <input
                  type="text"
                  placeholder={`Ingredient ${i + 1}`}
                  value={ing}
                  onChange={(e) => updateIngredient(i, e.target.value)}
                  className="flex-1 bg-white border border-[rgba(43,36,32,0.1)] rounded-xl px-3 py-2.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none focus:border-[#D9713C] transition-colors"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                />
                {ingredients.length > 1 && (
                  <button onClick={() => removeIngredient(i)} className="p-1 text-[#C4B8B3] hover:text-[#9C8F8A]">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" /></svg>
                  </button>
                )}
              </div>
            ))}
          </div>
          <button onClick={addIngredient} className="flex items-center gap-1.5 text-[#D9713C] text-sm font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12h14" stroke="#D9713C" strokeWidth="2.2" strokeLinecap="round" /></svg>
            Add ingredient
          </button>
        </div>

        {/* Steps builder */}
        <div>
          <label className="text-[#5C4F4A] text-xs font-semibold uppercase tracking-wide block mb-2" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Steps</label>
          <div className="space-y-3 mb-2">
            {steps.map((step, i) => (
              <div key={i} className="bg-white rounded-2xl border border-[rgba(43,36,32,0.08)] p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-[#D9713C] text-xs font-bold uppercase tracking-wide" style={{ fontFamily: "Outfit, sans-serif" }}>Step {i + 1}</span>
                  {steps.length > 1 && (
                    <button onClick={() => removeStep(i)} className="p-0.5 text-[#C4B8B3]">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" /></svg>
                    </button>
                  )}
                </div>
                <textarea
                  placeholder="Describe this step..."
                  value={step.text}
                  onChange={(e) => updateStep(i, "text", e.target.value)}
                  rows={2}
                  className="w-full text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none resize-none bg-transparent"
                  style={{ fontFamily: "Outfit, sans-serif" }}
                />
                <div className="flex items-center gap-2 pt-1 border-t border-[rgba(43,36,32,0.05)]">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="#9C8F8A" strokeWidth="1.8" /><path d="M12 7v5l3 3" stroke="#9C8F8A" strokeWidth="1.8" strokeLinecap="round" /></svg>
                  <input
                    type="text"
                    placeholder="Timer (optional, e.g. 5:00)"
                    value={step.timer}
                    onChange={(e) => updateStep(i, "timer", e.target.value)}
                    className="flex-1 text-[12px] text-[#5C4F4A] placeholder-[#C4B8B3] outline-none bg-transparent"
                    style={{ fontFamily: "Outfit, sans-serif" }}
                  />
                </div>
              </div>
            ))}
          </div>
          <button onClick={addStep} className="flex items-center gap-1.5 text-[#D9713C] text-sm font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12h14" stroke="#D9713C" strokeWidth="2.2" strokeLinecap="round" /></svg>
            Add step
          </button>
        </div>
      </div>

      {/* Publish button — pinned */}
      <div className="absolute bottom-0 left-0 right-0 bg-white/90 backdrop-blur-sm border-t border-[rgba(43,36,32,0.07)] px-5 py-4 pb-8">
        <button
          onClick={onPublish}
          className="w-full bg-[#D9713C] text-white py-4 rounded-full text-base font-semibold shadow-[0_4px_20px_rgba(217,113,60,0.35)] active:scale-[0.98] transition-transform"
          style={{ fontFamily: "Outfit, sans-serif" }}
        >
          Publish Recipe
        </button>
      </div>
    </div>
  );
}

// ─── Screen: Admin Dashboard ──────────────────────────────────────────────────

function AdminDashboardScreen({ onBack, onManage, items }: { onBack: () => void; onManage: () => void; items: AdminSubmission[] }) {
  const flaggedCount = items.filter((s) => s.status === "flagged").length;
  const stats = [
    { label: "Total Users", value: "4,281", icon: "👥", delta: "+12 today" },
    { label: "Total Recipes", value: String(items.length + 1039), icon: "🍽", delta: "+8 today" },
    { label: "This Week", value: "63", icon: "📅", delta: "recipes submitted" },
    { label: "Flagged", value: String(flaggedCount), icon: "🚩", delta: "needs review", urgent: flaggedCount > 0 },
  ];

  const recent = items.slice(0, 5);

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-14 px-5 pb-4">
        <div className="flex items-center gap-3 mb-1">
          <button onClick={onBack} className="p-1">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-[#2B2420] text-xl" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Admin Dashboard</h1>
              <span className="text-[10px] font-bold text-white bg-[#D9713C] px-2 py-0.5 rounded-full uppercase tracking-wide" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Admin</span>
            </div>
            <p className="text-[#9C8F8A] text-[12px]" style={{ fontFamily: "Outfit, sans-serif" }}>Sep 11, 2026</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar px-5 pb-10 space-y-5">
        {/* Stat cards — 2×2 grid */}
        <div className="grid grid-cols-2 gap-3">
          {stats.map((s) => (
            <div
              key={s.label}
              className={`bg-white rounded-[20px] p-4 shadow-[0_2px_12px_rgba(43,36,32,0.07)] ${s.urgent ? "border border-[rgba(217,113,60,0.25)]" : ""}`}
            >
              <div className="text-2xl mb-2">{s.icon}</div>
              <p className="text-[#2B2420] text-2xl font-bold leading-none mb-1" style={{ fontFamily: "Outfit, sans-serif" }}>{s.value}</p>
              <p className="text-[#5C4F4A] text-[12px] font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>{s.label}</p>
              <p className={`text-[11px] mt-1 ${s.urgent ? "text-[#D9713C]" : "text-[#8A9B6E]"}`} style={{ fontFamily: "Outfit, sans-serif" }}>{s.delta}</p>
            </div>
          ))}
        </div>

        {/* Recent submissions */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-[#2B2420] text-base font-semibold" style={{ fontFamily: "Lora, serif" }}>Recent Submissions</h2>
            <button onClick={onManage} className="text-[#D9713C] text-sm font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>See all →</button>
          </div>
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(43,36,32,0.07)] divide-y divide-[rgba(43,36,32,0.05)] overflow-hidden">
            {recent.map((sub) => (
              <div key={sub.id} className="flex items-center gap-3 px-4 py-3.5">
                <div className="flex-1 min-w-0">
                  <p className="text-[#2B2420] text-sm font-semibold truncate" style={{ fontFamily: "Outfit, sans-serif" }}>{sub.title}</p>
                  <p className="text-[#9C8F8A] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>@{sub.uploader} · {sub.date}</p>
                </div>
                <span className={`flex-shrink-0 text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                  sub.status === "flagged" ? "bg-[#D9713C]/15 text-[#D9713C]" : "bg-[#8A9B6E]/15 text-[#8A9B6E]"
                }`} style={{ fontFamily: "Outfit, sans-serif" }}>
                  {sub.status}
                </span>
                <div className="flex gap-1.5 flex-shrink-0">
                  <button className="text-[#9C8F8A] p-1 hover:text-[#2B2420]">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" strokeWidth="1.8" /><circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.8" /></svg>
                  </button>
                  <button className="text-[#9C8F8A] p-1 hover:text-[#D9713C]">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><polyline points="3 6 5 6 21 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" /><path d="M19 6l-1 14H6L5 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /><path d="M10 11v6M14 11v6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" /></svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick action */}
        <button
          onClick={onManage}
          className="w-full flex items-center justify-between bg-white rounded-[20px] p-4 shadow-[0_2px_12px_rgba(43,36,32,0.07)] border border-[rgba(217,113,60,0.15)] active:scale-[0.99] transition-transform"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-[#D9713C]/10 flex items-center justify-center">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><rect x="3" y="3" width="7" height="7" rx="1" stroke="#D9713C" strokeWidth="1.8" /><rect x="14" y="3" width="7" height="7" rx="1" stroke="#D9713C" strokeWidth="1.8" /><rect x="3" y="14" width="7" height="7" rx="1" stroke="#D9713C" strokeWidth="1.8" /><rect x="14" y="14" width="7" height="7" rx="1" stroke="#D9713C" strokeWidth="1.8" /></svg>
            </div>
            <div className="text-left">
              <p className="text-[#2B2420] text-sm font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>Manage All Recipes</p>
              <p className="text-[#9C8F8A] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>Search, filter, review & remove</p>
            </div>
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M9 18l6-6-6-6" stroke="#C4B8B3" strokeWidth="2" strokeLinecap="round" /></svg>
        </button>
      </div>
    </div>
  );
}

// ─── Screen: Admin Recipe Management ─────────────────────────────────────────

function AdminRecipesScreen({
  onBack,
  onDetail,
  items,
  setItems,
}: {
  onBack: () => void;
  onDetail: (id: string) => void;
  items: AdminSubmission[];
  setItems: React.Dispatch<React.SetStateAction<AdminSubmission[]>>;
}) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | "visible" | "flagged" | "removed">("all");

  const remove = (id: string) => setItems((prev) => prev.map((r) => r.id === id ? { ...r, status: "removed" as AdminStatus } : r));
  const flag = (id: string) => setItems((prev) => prev.map((r) => r.id === id ? { ...r, status: r.status === "flagged" ? "visible" as AdminStatus : "flagged" as AdminStatus } : r));

  const shown = items.filter((r) => {
    const matchSearch = !search || r.title.toLowerCase().includes(search.toLowerCase()) || r.uploader.includes(search.toLowerCase());
    const matchStatus = statusFilter === "all" || r.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const statusColor: Record<AdminStatus, string> = {
    visible: "bg-[#8A9B6E]/15 text-[#8A9B6E]",
    flagged: "bg-[#D9713C]/15 text-[#D9713C]",
    removed: "bg-[rgba(43,36,32,0.08)] text-[#9C8F8A]",
  };
  const statusIcon: Record<AdminStatus, string> = { visible: "✓", flagged: "🚩", removed: "✕" };

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-14 px-5 pb-4 border-b border-[rgba(43,36,32,0.07)]">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
          <h1 className="text-[#2B2420] text-xl flex-1" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Recipe Management</h1>
          <span className="text-[10px] font-bold text-white bg-[#D9713C] px-2 py-0.5 rounded-full uppercase" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Admin</span>
        </div>

        {/* Search */}
        <div className="relative mb-3">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="#9C8F8A" strokeWidth="2" /><path d="M16.5 16.5L21 21" stroke="#9C8F8A" strokeWidth="2" strokeLinecap="round" /></svg>
          </div>
          <input
            type="text"
            placeholder="Search by title or uploader..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white rounded-full pl-10 pr-4 py-2.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] shadow-[0_1px_8px_rgba(43,36,32,0.07)] outline-none border border-[rgba(43,36,32,0.06)]"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
        </div>

        {/* Status filter */}
        <div className="flex gap-2 flex-wrap">
          {(["all", "visible", "flagged", "removed"] as const).map((s) => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3.5 py-1.5 rounded-full text-[13px] font-medium capitalize border transition-all ${
                statusFilter === s
                  ? s === "flagged" ? "bg-[#D9713C] text-white border-[#D9713C]"
                  : s === "removed" ? "bg-[#2B2420] text-white border-[#2B2420]"
                  : "bg-[#2B2420] text-white border-[#2B2420]"
                  : "bg-white text-[#5C4F4A] border-[rgba(43,36,32,0.1)]"
              }`}
              style={{ fontFamily: "Outfit, sans-serif" }}
            >
              {s}
              {s !== "all" && (
                <span className={`ml-1.5 text-[10px] font-bold px-1.5 py-0.5 rounded-full ${statusFilter === s ? "bg-white/20" : "opacity-60"}`}>
                  {items.filter((r) => r.status === s).length}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Recipe table */}
      <div className="flex-1 overflow-y-auto no-scrollbar">
        {/* Column header */}
        <div className="flex items-center gap-3 px-5 py-2 border-b border-[rgba(43,36,32,0.06)]">
          <span className="flex-1 text-[10px] font-semibold text-[#9C8F8A] uppercase tracking-widest" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}>Recipe / Uploader</span>
          <span className="w-14 text-center text-[10px] font-semibold text-[#9C8F8A] uppercase tracking-widest" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}>Status</span>
          <span className="w-16 text-center text-[10px] font-semibold text-[#9C8F8A] uppercase tracking-widest" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}>Actions</span>
        </div>

        {shown.map((sub) => (
          <div
            key={sub.id}
            className={`flex items-center gap-3 px-5 py-4 border-b border-[rgba(43,36,32,0.05)] ${
              sub.status === "flagged" ? "bg-[rgba(217,113,60,0.03)]" :
              sub.status === "removed" ? "bg-[rgba(43,36,32,0.02)] opacity-60" : ""
            }`}
          >
            {/* Main tap area → detail */}
            <button
              onClick={() => onDetail(sub.id)}
              className="flex-1 min-w-0 text-left active:opacity-70 transition-opacity"
            >
              <p className="text-[#2B2420] text-sm font-semibold truncate" style={{ fontFamily: "Outfit, sans-serif" }}>{sub.title}</p>
              <p className="text-[#9C8F8A] text-[11px] mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>@{sub.uploader} · {sub.date}</p>
            </button>
            <div className="w-16 flex justify-center flex-shrink-0">
              <span className={`text-[10px] font-semibold px-2 py-1 rounded-full ${statusColor[sub.status]}`} style={{ fontFamily: "Outfit, sans-serif" }}>
                {statusIcon[sub.status]} {sub.status}
              </span>
            </div>
            <div className="w-12 flex items-center justify-center gap-0.5 flex-shrink-0">
              {/* Flag/unflag */}
              <button
                onClick={() => flag(sub.id)}
                title={sub.status === "flagged" ? "Unflag" : "Flag"}
                className={`p-1.5 rounded-lg transition-colors ${sub.status === "flagged" ? "bg-[#D9713C]/15 text-[#D9713C]" : "text-[#C4B8B3] hover:text-[#D9713C]"}`}
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill={sub.status === "flagged" ? "#D9713C" : "none"}><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22v-7" stroke={sub.status === "flagged" ? "#D9713C" : "currentColor"} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>
              </button>
              {/* Remove */}
              <button
                onClick={() => remove(sub.id)}
                title="Remove"
                className="p-1.5 rounded-lg text-[#C4B8B3] hover:text-[#9C2B2B] transition-colors"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><polyline points="3 6 5 6 21 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" /><path d="M19 6l-1 14H6L5 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /><path d="M10 11v6M14 11v6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" /></svg>
              </button>
            </div>
          </div>
        ))}

        {shown.length === 0 && (
          <div className="text-center py-16 text-[#9C8F8A]">
            <div className="text-4xl mb-3">🔍</div>
            <p style={{ fontFamily: "Outfit, sans-serif" }}>No recipes match your filter</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Screen: User Profile (Public View) ──────────────────────────────────────

function UserProfileScreen({
  uploader,
  onBack,
  onMessage,
  onRecipe,
  ratings,
}: {
  uploader: string;
  onBack: () => void;
  onMessage: () => void;
  onRecipe: (r: Recipe) => void;
  ratings: Record<string, RecipeRatingData>;
}) {
  const user = COMMUNITY_USERS[uploader] ?? {
    uploader,
    avatarColor: "#9C8F8A",
    bio: "Community member.",
    recipesCount: 0,
    totalLikes: 0,
  };

  const userRecipes = COMMUNITY_RECIPES.filter((r) => r.uploader === uploader);

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col overflow-y-auto no-scrollbar">
      {/* Header banner with back button */}
      <div className="relative bg-gradient-to-b from-[#EDE0D3] to-[#F5EDE4]" style={{ height: 180 }}>
        <button
          onClick={onBack}
          className="absolute top-12 left-4 w-10 h-10 rounded-full bg-white/80 backdrop-blur-sm flex items-center justify-center shadow-sm z-10"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>

      {/* Avatar row — sits below header, overlapping bottom edge */}
      <div className="px-5 mb-4" style={{ marginTop: -48 }}>
        <div className="flex items-end justify-between">
          <div
            className="w-24 h-24 rounded-full border-4 border-[#FDF8F3] flex items-center justify-center shadow-[0_4px_20px_rgba(0,0,0,0.15)] text-white font-bold"
            style={{ background: user.avatarColor, fontFamily: "Lora, serif", fontSize: 34, lineHeight: 1 }}
          >
            {uploader[0].toUpperCase()}
          </div>
          {/* Message button — vertically aligned to bottom of avatar */}
          <button
            onClick={onMessage}
            className="mb-1 flex items-center gap-1.5 px-5 py-2.5 rounded-full border-2 border-[#D9713C] text-[#D9713C] text-sm font-semibold active:opacity-70 transition-opacity"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
              <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" stroke="#D9713C" strokeWidth="2" strokeLinejoin="round" />
            </svg>
            Message
          </button>
        </div>

        {/* Name + username */}
        <h1
          className="text-[#2B2420] text-xl mt-3 leading-tight"
          style={{ fontFamily: "Lora, serif", fontWeight: 600 }}
        >
          {uploader.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
        </h1>
        <p className="text-[#9C8F8A] text-[13px] mb-2" style={{ fontFamily: "Outfit, sans-serif" }}>
          @{uploader}
        </p>
        <p className="text-[#5C4F4A] text-sm leading-relaxed" style={{ fontFamily: "Outfit, sans-serif" }}>
          {user.bio}
        </p>

        {/* Stats row */}
        <div className="flex gap-6 mt-4 pb-4 border-b border-[rgba(43,36,32,0.08)]">
          {[
            { label: "Recipes", value: user.recipesCount },
            { label: "Total Likes", value: user.totalLikes.toLocaleString() },
          ].map((s) => (
            <div key={s.label}>
              <p className="text-[#2B2420] text-xl font-bold leading-none" style={{ fontFamily: "Outfit, sans-serif" }}>
                {s.value}
              </p>
              <p className="text-[#9C8F8A] text-[12px] mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>
                {s.label}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* Their recipes grid */}
      <div className="px-5 pb-10">
        <h2 className="text-[#2B2420] text-base mb-3" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>
          Published Recipes
        </h2>
        {userRecipes.length > 0 ? (
          <div className="grid grid-cols-2 gap-3">
            {userRecipes.map((r) => (
              <RecipeCard key={r.id} recipe={r} rating={ratings[r.id]} onTap={() => onRecipe(r)} />
            ))}
          </div>
        ) : (
          <div className="text-center py-12 text-[#9C8F8A]">
            <div className="text-3xl mb-2">🍽</div>
            <p className="text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>No recipes yet</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Screen: Conversations List ───────────────────────────────────────────────

function ConversationsScreen({
  onBack,
  onConversation,
}: {
  onBack: () => void;
  onConversation: (uploader: string) => void;
}) {
  const [search, setSearch] = useState("");
  const shown = CONVERSATIONS.filter(
    (c) => !search || c.uploader.includes(search.toLowerCase()),
  );
  const totalUnread = CONVERSATIONS.reduce((n, c) => n + c.unread, 0);

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-14 px-5 pb-4 border-b border-[rgba(43,36,32,0.07)]">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
          <div className="flex items-center gap-2 flex-1">
            <h1 className="text-[#2B2420] text-xl" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Messages</h1>
            {totalUnread > 0 && (
              <span className="w-5 h-5 rounded-full bg-[#D9713C] text-white text-[10px] font-bold flex items-center justify-center" style={{ fontFamily: "Outfit, sans-serif" }}>
                {totalUnread}
              </span>
            )}
          </div>
          <button className="w-9 h-9 rounded-full bg-[#D9713C]/10 flex items-center justify-center">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M12 5v14M5 12h14" stroke="#D9713C" strokeWidth="2.2" strokeLinecap="round" />
            </svg>
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
              <circle cx="11" cy="11" r="7" stroke="#9C8F8A" strokeWidth="2" />
              <path d="M16.5 16.5L21 21" stroke="#9C8F8A" strokeWidth="2" strokeLinecap="round" />
            </svg>
          </div>
          <input
            type="text"
            placeholder="Search conversations..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white rounded-full pl-9 pr-4 py-2.5 text-sm text-[#2B2420] placeholder-[#C4B8B3] shadow-[0_1px_6px_rgba(43,36,32,0.06)] outline-none border border-[rgba(43,36,32,0.06)]"
            style={{ fontFamily: "Outfit, sans-serif" }}
          />
        </div>
      </div>

      {/* Conversation list */}
      <div className="flex-1 overflow-y-auto no-scrollbar divide-y divide-[rgba(43,36,32,0.05)]">
        {shown.map((conv) => (
          <button
            key={conv.id}
            onClick={() => onConversation(conv.uploader)}
            className="w-full flex items-center gap-4 px-5 py-4 active:bg-[rgba(43,36,32,0.03)] transition-colors text-left"
          >
            {/* Avatar */}
            <div className="relative flex-shrink-0">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center text-white text-lg font-bold shadow-sm"
                style={{ background: conv.avatarColor, fontFamily: "Lora, serif" }}
              >
                {conv.uploader[0].toUpperCase()}
              </div>
              {conv.unread > 0 && (
                <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-[#D9713C] text-white text-[9px] font-bold flex items-center justify-center" style={{ fontFamily: "Outfit, sans-serif" }}>
                  {conv.unread}
                </span>
              )}
            </div>

            {/* Text */}
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline justify-between mb-0.5">
                <p
                  className={`text-sm ${conv.unread > 0 ? "text-[#2B2420] font-semibold" : "text-[#5C4F4A] font-medium"}`}
                  style={{ fontFamily: "Outfit, sans-serif" }}
                >
                  @{conv.uploader}
                </p>
                <span className="text-[11px] text-[#C4B8B3] flex-shrink-0 ml-2" style={{ fontFamily: "Outfit, sans-serif" }}>
                  {conv.timestamp}
                </span>
              </div>
              <p
                className={`text-[13px] truncate ${conv.unread > 0 ? "text-[#5C4F4A] font-medium" : "text-[#9C8F8A]"}`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {conv.lastMessage}
              </p>
            </div>

            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" className="flex-shrink-0 opacity-30">
              <path d="M9 18l6-6-6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── Screen: Chat ─────────────────────────────────────────────────────────────

function ChatScreen({
  uploader,
  onBack,
}: {
  uploader: string;
  onBack: () => void;
}) {
  const user = COMMUNITY_USERS[uploader];
  const avatarColor = user?.avatarColor ?? "#9C8F8A";
  const displayName = uploader.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

  const initial = CHAT_HISTORY[uploader] ?? [];
  const [messages, setMessages] = useState<ChatMessage[]>(initial);
  const [input, setInput] = useState("");

  const send = () => {
    const text = input.trim();
    if (!text) return;
    const newMsg: ChatMessage = { id: String(Date.now()), role: "me", text, time: "Now" };
    setMessages((prev) => [...prev, newMsg]);
    setInput("");
    // Simulate reply after a short delay
    setTimeout(() => {
      setMessages((prev) => [
        ...prev,
        { id: String(Date.now() + 1), role: "them", text: "Thanks for the message! I'll get back to you soon 😊", time: "Now" },
      ]);
    }, 1200);
  };

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-12 pb-3 px-4 border-b border-[rgba(43,36,32,0.07)] flex items-center gap-3 bg-white/90 backdrop-blur-sm">
        <button onClick={onBack} className="p-1 flex-shrink-0">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
        <div
          className="w-9 h-9 rounded-full flex-shrink-0 flex items-center justify-center text-white text-sm font-bold"
          style={{ background: avatarColor, fontFamily: "Lora, serif" }}
        >
          {uploader[0].toUpperCase()}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-[#2B2420] text-[15px] font-semibold leading-tight truncate" style={{ fontFamily: "Outfit, sans-serif" }}>
            {displayName}
          </p>
          <p className="text-[#9C8F8A] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>
            @{uploader} · Active recently
          </p>
        </div>
        <button className="p-1 text-[#9C8F8A]">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="5" r="1.5" fill="currentColor" />
            <circle cx="12" cy="12" r="1.5" fill="currentColor" />
            <circle cx="12" cy="19" r="1.5" fill="currentColor" />
          </svg>
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto no-scrollbar px-4 py-5 space-y-3">
        {/* Date separator */}
        <div className="flex items-center gap-3 my-2">
          <div className="flex-1 h-px bg-[rgba(43,36,32,0.08)]" />
          <span className="text-[11px] text-[#C4B8B3]" style={{ fontFamily: "Outfit, sans-serif" }}>Today</span>
          <div className="flex-1 h-px bg-[rgba(43,36,32,0.08)]" />
        </div>

        {messages.map((msg) => (
          <div key={msg.id} className={`flex ${msg.role === "me" ? "justify-end" : "justify-start"} gap-2`}>
            {msg.role === "them" && (
              <div
                className="w-7 h-7 rounded-full flex-shrink-0 flex items-center justify-center text-white text-[11px] font-bold self-end mb-1"
                style={{ background: avatarColor, fontFamily: "Lora, serif" }}
              >
                {uploader[0].toUpperCase()}
              </div>
            )}
            <div className="max-w-[72%]">
              <div
                className={`px-4 py-2.5 text-sm leading-relaxed ${
                  msg.role === "me"
                    ? "bg-[#D9713C] text-white rounded-[18px] rounded-br-[5px]"
                    : "bg-white border border-[rgba(43,36,32,0.1)] text-[#2B2420] rounded-[18px] rounded-bl-[5px] shadow-[0_1px_4px_rgba(43,36,32,0.06)]"
                }`}
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                {msg.text}
              </div>
              <p className={`text-[10px] text-[#C4B8B3] mt-1 ${msg.role === "me" ? "text-right" : "text-left"}`} style={{ fontFamily: "Outfit, sans-serif" }}>
                {msg.time}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Input bar */}
      <div className="px-4 pb-8 pt-3 bg-white border-t border-[rgba(43,36,32,0.07)] flex items-center gap-2">
        <input
          type="text"
          placeholder="Type a message..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && send()}
          className="flex-1 bg-[#F5EFE9] rounded-full px-4 py-3 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none"
          style={{ fontFamily: "Outfit, sans-serif" }}
        />
        <button
          onClick={send}
          disabled={!input.trim()}
          className="w-11 h-11 rounded-full bg-[#D9713C] flex items-center justify-center flex-shrink-0 shadow-[0_2px_10px_rgba(217,113,60,0.3)] disabled:opacity-40 active:scale-95 transition-all"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M22 2L11 13M22 2L15 22l-4-9-9-4 20-7z" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>
    </div>
  );
}

// ─── Screen: Notifications ───────────────────────────────────────────────────

function NotificationsScreen({
  notifications,
  onBack,
  onMarkAllRead,
  onRecipe,
}: {
  notifications: Notification[];
  onBack: () => void;
  onMarkAllRead: () => void;
  onRecipe: (recipeId: string) => void;
}) {
  const unreadCount = notifications.filter((n) => !n.read).length;

  const notifIcon = (type: Notification["type"]) => {
    if (type === "cooked") return (
      <div className="w-8 h-8 rounded-full bg-[#8A9B6E]/15 flex items-center justify-center">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" stroke="#8A9B6E" strokeWidth="1.6" /><circle cx="12" cy="9" r="2.5" stroke="#8A9B6E" strokeWidth="1.6" /></svg>
      </div>
    );
    if (type === "liked") return (
      <div className="w-8 h-8 rounded-full bg-[#D9713C]/12 flex items-center justify-center">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="#D9713C"><path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" /></svg>
      </div>
    );
    if (type === "commented") return (
      <div className="w-8 h-8 rounded-full bg-[rgba(43,36,32,0.07)] flex items-center justify-center">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" stroke="#5C4F4A" strokeWidth="1.6" strokeLinejoin="round" /></svg>
      </div>
    );
    if (type === "flagged") return (
      <div className="w-8 h-8 rounded-full bg-[rgba(217,166,60,0.15)] flex items-center justify-center">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22v-7" stroke="#B8860B" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>
      </div>
    );
    if (type === "removed") return (
      <div className="w-8 h-8 rounded-full bg-[rgba(156,43,43,0.10)] flex items-center justify-center">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><polyline points="3 6 5 6 21 6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" /><path d="M19 6l-1 14H6L5 6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>
      </div>
    );
    return (
      <div className="w-8 h-8 rounded-full bg-[#8A9B6E]/15 flex items-center justify-center">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M5 3h14a1 1 0 011 1v17l-8-4-8 4V4a1 1 0 011-1z" stroke="#8A9B6E" strokeWidth="1.6" /></svg>
      </div>
    );
  };

  const notifText = (n: Notification) => {
    if (n.type === "cooked") return <><span className="font-semibold text-[#2B2420]">@{n.fromUser}</span> cooked your <span className="font-semibold text-[#2B2420]">{n.recipeName}</span></>;
    if (n.type === "liked") return <><span className="font-semibold text-[#2B2420]">@{n.fromUser}</span> liked your recipe <span className="font-semibold text-[#2B2420]">{n.recipeName}</span></>;
    if (n.type === "commented") return <><span className="font-semibold text-[#2B2420]">@{n.fromUser}</span> commented on <span className="font-semibold text-[#2B2420]">{n.recipeName}</span></>;
    if (n.type === "flagged") return (
      <span>Your recipe <span className="font-semibold text-[#2B2420]">{n.recipeName}</span> was flagged{n.adminReason ? <span className="text-[#B8860B]">: "{n.adminReason}"</span> : ""}</span>
    );
    if (n.type === "removed") return (
      <span>Your recipe <span className="font-semibold text-[#2B2420]">{n.recipeName}</span> was removed{n.adminReason ? <span className="text-[#9C2B2B]">: "{n.adminReason}"</span> : ""}</span>
    );
    return <><span className="font-semibold text-[#2B2420]">@{n.fromUser}</span> saved your recipe <span className="font-semibold text-[#2B2420]">{n.recipeName}</span></>;
  };

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-14 px-5 pb-4 border-b border-[rgba(43,36,32,0.07)]">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button onClick={onBack} className="p-1 -ml-1">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
            <div>
              <h1 className="text-[#2B2420] text-xl" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Notifications</h1>
              {unreadCount > 0 && <p className="text-[#9C8F8A] text-[12px] mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>{unreadCount} unread</p>}
            </div>
          </div>
          {unreadCount > 0 && (
            <button onClick={onMarkAllRead} className="text-[#D9713C] text-[13px] font-semibold active:opacity-60 transition-opacity" style={{ fontFamily: "Outfit, sans-serif" }}>
              Mark all read
            </button>
          )}
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto no-scrollbar">
        {notifications.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full gap-3">
            <div className="w-16 h-16 rounded-full bg-[rgba(43,36,32,0.06)] flex items-center justify-center">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
                <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0" stroke="#9C8F8A" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <p className="text-[#9C8F8A] text-sm" style={{ fontFamily: "Outfit, sans-serif" }}>No notifications yet</p>
          </div>
        ) : (
          <div>
            {notifications.map((n, idx) => (
              <button
                key={n.id}
                onClick={() => onRecipe(n.recipeId)}
                className={`w-full flex items-start gap-3 px-5 py-4 text-left transition-colors active:bg-[rgba(43,36,32,0.03)] ${!n.read ? "bg-[rgba(217,113,60,0.04)]" : ""} ${idx < notifications.length - 1 ? "border-b border-[rgba(43,36,32,0.06)]" : ""}`}
              >
                {/* User avatar */}
                <div
                  className="w-10 h-10 rounded-full flex-shrink-0 flex items-center justify-center text-white text-[13px] font-bold"
                  style={{ background: n.avatarColor, fontFamily: "Lora, serif" }}
                >
                  {n.fromUser[0].toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-[#5C4F4A] text-[13px] leading-relaxed" style={{ fontFamily: "Outfit, sans-serif" }}>
                    {notifText(n)}
                  </p>
                  <div className="flex items-center gap-2 mt-1">
                    {notifIcon(n.type)}
                    <span className="text-[#C4B8B3] text-[11px]" style={{ fontFamily: "Outfit, sans-serif" }}>{n.timestamp}</span>
                  </div>
                </div>
                {!n.read && (
                  <div className="w-2 h-2 rounded-full bg-[#D9713C] flex-shrink-0 mt-1.5" />
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Screen: Admin Recipe Detail ─────────────────────────────────────────────

function AdminRecipeDetailScreen({
  submission,
  onBack,
  onApprove,
  onFlag,
  onRemove,
}: {
  submission: AdminSubmission;
  onBack: () => void;
  onApprove: () => void;
  onFlag: (reason: string) => void;
  onRemove: (reason: string) => void;
}) {
  const [checkedIngredients, setCheckedIngredients] = useState<Set<number>>(new Set());
  const [showSteps, setShowSteps] = useState(false);
  const [lightbox, setLightbox] = useState(false);

  // Confirmation sheet state
  type PendingAction = "flag" | "remove" | null;
  const [pendingAction, setPendingAction] = useState<PendingAction>(null);
  const [reasonText, setReasonText] = useState("");

  const toggleIngredient = (i: number) => {
    setCheckedIngredients((prev) => {
      const s = new Set(prev);
      if (s.has(i)) s.delete(i); else s.add(i);
      return s;
    });
  };

  const statusStyle: Record<AdminStatus, { bg: string; text: string; label: string }> = {
    visible: { bg: "bg-[#8A9B6E]/15", text: "text-[#8A9B6E]", label: "✓ Visible" },
    flagged: { bg: "bg-[#D9713C]/15", text: "text-[#D9713C]", label: "🚩 Flagged" },
    removed: { bg: "bg-[rgba(43,36,32,0.08)]", text: "text-[#9C8F8A]", label: "✕ Removed" },
  };
  const ss = statusStyle[submission.status];

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {lightbox && (
        <FullscreenImageViewer src={submission.image} alt={submission.title} onClose={() => setLightbox(false)} />
      )}
      {/* Hero image */}
      <div className="relative">
        <div className="relative bg-[#E8DDD5]" style={{ height: "338px" }}>
          <img
            src={submission.image}
            alt={submission.title}
            className="absolute inset-0 w-full h-full object-cover cursor-zoom-in"
            onClick={() => setLightbox(true)}
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent pointer-events-none" />
          {/* Expand hint */}
          <div className="absolute bottom-16 right-4 pointer-events-none">
            <div className="w-8 h-8 rounded-full bg-black/30 backdrop-blur-sm flex items-center justify-center">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
          {/* Back */}
          <button
            onClick={onBack}
            className="absolute top-12 left-4 w-10 h-10 rounded-full bg-white/80 backdrop-blur-sm flex items-center justify-center shadow-sm"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M15 18l-6-6 6-6" stroke="#2B2420" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
          {/* Admin badge */}
          <div className="absolute top-12 right-4">
            <span className="text-[10px] font-bold text-white bg-[#D9713C] px-2.5 py-1 rounded-full uppercase tracking-wide" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>🛡 Admin View</span>
          </div>

          {/* Glassmorphic recipe info card */}
          <div className="absolute bottom-0 left-4 right-4 translate-y-1/3">
            <div className="glass-card rounded-[20px] p-4 shadow-[0_8px_32px_rgba(43,36,32,0.12)]">
              <div className="flex items-start justify-between mb-2">
                <h1 className="text-[#2B2420] text-lg leading-tight flex-1 mr-2" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>
                  {submission.title}
                </h1>
                <span className={`flex-shrink-0 text-[11px] font-semibold px-2.5 py-1 rounded-full ${ss.bg} ${ss.text}`} style={{ fontFamily: "Outfit, sans-serif" }}>
                  {ss.label}
                </span>
              </div>
              <div className="flex gap-4">
                {[
                  { icon: "🌍", label: submission.cuisine },
                  { icon: "👥", label: `${submission.servings} servings` },
                  { icon: "📊", label: submission.difficulty },
                ].map((item) => (
                  <div key={item.label} className="text-center">
                    <div className="text-sm">{item.icon}</div>
                    <div className="text-[11px] text-[#5C4F4A] font-medium mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>{item.label}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto no-scrollbar">
      <div className="mt-20 px-5 pb-8 space-y-5">
        {/* ── Admin-only uploader info bar ── */}
        <div className="bg-white rounded-2xl border border-[rgba(43,36,32,0.08)] shadow-[0_1px_8px_rgba(43,36,32,0.06)] overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3 pb-2 border-b border-[rgba(43,36,32,0.06)]">
            <span className="text-[10px] font-bold text-[#D9713C] uppercase tracking-wide" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.07em" }}>🛡 Submission Info</span>
          </div>
          <div className="px-4 py-3 space-y-2">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-[#D9713C]/15 flex items-center justify-center text-sm font-bold text-[#D9713C]" style={{ fontFamily: "Lora, serif" }}>
                {submission.uploader[0].toUpperCase()}
              </div>
              <div>
                <p className="text-[#2B2420] text-sm font-semibold" style={{ fontFamily: "Outfit, sans-serif" }}>@{submission.uploader}</p>
                <p className="text-[#9C8F8A] text-[12px]" style={{ fontFamily: "Outfit, sans-serif" }}>{submission.email}</p>
              </div>
              <div className="ml-auto text-right">
                <p className="text-[#9C8F8A] text-[10px] uppercase tracking-wide font-semibold" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Submitted</p>
                <p className="text-[#5C4F4A] text-[12px] font-medium" style={{ fontFamily: "Outfit, sans-serif" }}>{submission.date}</p>
              </div>
            </div>
          </div>
        </div>

        {/* ── Flag reason box — only if flagged ── */}
        {submission.status === "flagged" && submission.flagReasons && (
          <div className="rounded-2xl border border-[rgba(217,113,60,0.3)] bg-[rgba(217,113,60,0.06)] overflow-hidden">
            <div className="flex items-center gap-2 px-4 pt-3 pb-2 border-b border-[rgba(217,113,60,0.15)]">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" stroke="#D9713C" strokeWidth="1.8" /><line x1="12" y1="9" x2="12" y2="13" stroke="#D9713C" strokeWidth="1.8" strokeLinecap="round" /><circle cx="12" cy="17" r="0.5" fill="#D9713C" stroke="#D9713C" strokeWidth="1.5" />
              </svg>
              <span className="text-[11px] font-bold text-[#D9713C] uppercase tracking-wide" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.06em" }}>Flag Reasons</span>
            </div>
            <div className="px-4 py-3 space-y-2">
              {submission.flagReasons.map((reason, i) => (
                <div key={i} className="flex gap-2.5">
                  <span className="text-[#D9713C] text-[11px] font-bold mt-0.5 flex-shrink-0">{i + 1}.</span>
                  <p className="text-[#5C4F4A] text-[13px] leading-relaxed" style={{ fontFamily: "Outfit, sans-serif" }}>{reason}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ── Ingredients (same as Recipe Overview) ── */}
        <div>
          <h2 className="text-[#2B2420] text-lg mb-3" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Ingredients</h2>
          <div className="space-y-3">
            {submission.ingredients.map((ing, i) => (
              <button key={i} onClick={() => toggleIngredient(i)} className="w-full flex items-center gap-3 text-left">
                <div className={`w-5 h-5 rounded-md flex-shrink-0 flex items-center justify-center border transition-all ${checkedIngredients.has(i) ? "bg-[#8A9B6E] border-[#8A9B6E]" : "border-[rgba(43,36,32,0.2)] bg-white"}`}>
                  {checkedIngredients.has(i) && (
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M2 6l3 3 5-5" stroke="white" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" /></svg>
                  )}
                </div>
                <span className={`text-sm transition-all ${checkedIngredients.has(i) ? "text-[#9C8F8A] line-through" : "text-[#2B2420]"}`} style={{ fontFamily: "Outfit, sans-serif" }}>{ing}</span>
              </button>
            ))}
          </div>
        </div>

        {/* ── Instructions accordion ── */}
        <div>
          <button
            onClick={() => setShowSteps(!showSteps)}
            className="w-full flex items-center justify-between py-4 border-t border-b border-[rgba(43,36,32,0.08)]"
          >
            <div className="text-left">
              <h2 className="text-[#2B2420] text-base font-semibold" style={{ fontFamily: "Lora, serif" }}>Instructions</h2>
              <p className="text-[#9C8F8A] text-xs mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>{submission.steps.length} steps</p>
            </div>
            <div className={`transition-transform ${showSteps ? "rotate-180" : ""}`}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M6 9l6 6 6-6" stroke="#9C8F8A" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
            </div>
          </button>
          {showSteps && (
            <div className="space-y-3 pt-4">
              {submission.steps.map((step, i) => (
                <div key={i} className="flex gap-3">
                  <div className="w-6 h-6 rounded-full bg-[#D9713C]/15 flex-shrink-0 flex items-center justify-center mt-0.5">
                    <span className="text-[11px] font-bold text-[#D9713C]" style={{ fontFamily: "Outfit, sans-serif" }}>{i + 1}</span>
                  </div>
                  <p className="text-sm text-[#5C4F4A] leading-relaxed" style={{ fontFamily: "Outfit, sans-serif" }}>{step}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
      </div>{/* end scrollable content */}

      {/* ── Admin action bar — sticky footer ── */}
      <div className="flex-shrink-0 bg-white/95 backdrop-blur-sm border-t border-[rgba(43,36,32,0.08)] px-5 pt-4 pb-9">
        <p className="text-[10px] font-semibold text-[#9C8F8A] uppercase tracking-widest mb-3 text-center" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}>Admin Actions</p>
        <div className="flex gap-2">
          <button
            onClick={onApprove}
            className="flex-1 flex flex-col items-center gap-1 py-3 rounded-2xl bg-[#8A9B6E]/15 border border-[rgba(138,155,110,0.3)] active:bg-[#8A9B6E]/25 transition-colors"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M20 6L9 17l-5-5" stroke="#8A9B6E" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>
            <span className="text-[12px] font-semibold text-[#8A9B6E]" style={{ fontFamily: "Outfit, sans-serif" }}>Approve</span>
          </button>
          <button
            onClick={() => { setPendingAction("flag"); setReasonText(""); }}
            className="flex-1 flex flex-col items-center gap-1 py-3 rounded-2xl bg-[rgba(217,166,60,0.12)] border border-[rgba(217,166,60,0.3)] active:bg-[rgba(217,166,60,0.22)] transition-colors"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22v-7" stroke="#B8860B" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
            <span className="text-[12px] font-semibold text-[#B8860B]" style={{ fontFamily: "Outfit, sans-serif" }}>Flag</span>
          </button>
          <button
            onClick={() => { setPendingAction("remove"); setReasonText(""); }}
            className="flex-1 flex flex-col items-center gap-1 py-3 rounded-2xl bg-[rgba(180,34,34,0.08)] border border-[rgba(180,34,34,0.2)] active:bg-[rgba(180,34,34,0.16)] transition-colors"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><polyline points="3 6 5 6 21 6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" /><path d="M19 6l-1 14H6L5 6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /><path d="M10 11v6M14 11v6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" /></svg>
            <span className="text-[12px] font-semibold text-[#9C2B2B]" style={{ fontFamily: "Outfit, sans-serif" }}>Remove</span>
          </button>
        </div>
      </div>

      {/* ── Confirmation bottom sheet ── */}
      {pendingAction && (
        <div className="absolute inset-0 z-20 flex flex-col justify-end">
          {/* Scrim */}
          <div
            className="absolute inset-0 bg-black/40"
            onClick={() => setPendingAction(null)}
          />
          {/* Sheet */}
          <div className="relative sheet-enter bg-[#FEFAF5] rounded-t-[28px] px-5 pt-6 pb-10 shadow-[0_-8px_40px_rgba(0,0,0,0.18)]">
            {/* Handle */}
            <div className="absolute top-2.5 left-1/2 -translate-x-1/2 w-10 h-1 rounded-full bg-[rgba(43,36,32,0.12)]" />

            {/* Title row */}
            <div className="flex items-center gap-3 mb-1">
              {pendingAction === "flag" ? (
                <div className="w-9 h-9 rounded-full bg-[rgba(217,166,60,0.15)] flex items-center justify-center flex-shrink-0">
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22v-7" stroke="#B8860B" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
                </div>
              ) : (
                <div className="w-9 h-9 rounded-full bg-[rgba(156,43,43,0.10)] flex items-center justify-center flex-shrink-0">
                  <svg width="17" height="17" viewBox="0 0 24 24" fill="none"><polyline points="3 6 5 6 21 6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" /><path d="M19 6l-1 14H6L5 6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /><path d="M10 11v6M14 11v6" stroke="#9C2B2B" strokeWidth="1.8" strokeLinecap="round" /></svg>
                </div>
              )}
              <div>
                <h3 className="text-[#2B2420] text-[17px]" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>
                  {pendingAction === "flag" ? "Flag this recipe" : "Remove this recipe"}
                </h3>
                <p className="text-[#9C8F8A] text-[12px] mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>
                  {pendingAction === "flag"
                    ? "The uploader will be notified with your reason."
                    : "This will hide the recipe from all users."}
                </p>
              </div>
            </div>

            {/* Reason field */}
            <div className="mt-5 mb-5">
              <label className="block text-[#5C4F4A] text-[13px] font-semibold mb-2" style={{ fontFamily: "Outfit, sans-serif" }}>
                Reason <span style={{ color: pendingAction === "remove" ? "#9C2B2B" : "#B8860B" }}>*</span>
              </label>
              <textarea
                value={reasonText}
                onChange={(e) => setReasonText(e.target.value)}
                placeholder={
                  pendingAction === "flag"
                    ? "Explain why you're flagging this recipe…"
                    : "Explain why you're removing this recipe…"
                }
                rows={3}
                className="w-full rounded-2xl border border-[rgba(43,36,32,0.12)] bg-white px-4 py-3 text-sm text-[#2B2420] placeholder-[#C4B8B3] outline-none resize-none focus:border-[rgba(43,36,32,0.28)] transition-colors"
                style={{ fontFamily: "Outfit, sans-serif" }}
              />
              {reasonText.trim().length === 0 && (
                <p className="text-[#C4B8B3] text-[11px] mt-1.5" style={{ fontFamily: "Outfit, sans-serif" }}>Required before confirming</p>
              )}
            </div>

            {/* Buttons */}
            <div className="flex gap-3">
              <button
                onClick={() => setPendingAction(null)}
                className="flex-1 py-3.5 rounded-full border-2 border-[rgba(43,36,32,0.15)] text-[#5C4F4A] text-[15px] font-semibold active:opacity-70 transition-opacity"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  const reason = reasonText.trim();
                  if (!reason) return;
                  if (pendingAction === "flag") onFlag(reason);
                  else onRemove(reason);
                  setPendingAction(null);
                }}
                disabled={reasonText.trim().length === 0}
                className="flex-1 py-3.5 rounded-full text-white text-[15px] font-semibold transition-all active:scale-[0.98] disabled:opacity-40"
                style={{
                  fontFamily: "Outfit, sans-serif",
                  background: reasonText.trim().length === 0
                    ? "#9C8F8A"
                    : pendingAction === "flag" ? "#B8860B" : "#9C2B2B",
                }}
              >
                {pendingAction === "flag" ? "Flag Recipe" : "Remove Recipe"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Screen: Grocery List ────────────────────────────────────────────────────

function GroceryListScreen({
  items,
  onToggle,
  onClearChecked,
  activeTab,
  onTab,
}: {
  items: GroceryItem[];
  onToggle: (id: string) => void;
  onClearChecked: () => void;
  activeTab: Tab;
  onTab: (t: Tab) => void;
}) {
  const checkedCount = items.filter((i) => i.checked).length;

  // Group by category, then within each group order unchecked first
  const grouped: Record<string, GroceryItem[]> = {};
  const categoryOrder = ["Produce", "Meat & Fish", "Dairy & Eggs", "Pantry", "Other"];
  for (const item of items) {
    if (!grouped[item.category]) grouped[item.category] = [];
    grouped[item.category].push(item);
  }
  const orderedGroups = categoryOrder.filter((c) => grouped[c]);

  return (
    <div className="absolute inset-0 bg-[#FDF8F3] flex flex-col">
      {/* Header */}
      <div className="pt-14 px-5 pb-4 border-b border-[rgba(43,36,32,0.07)]">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-[#2B2420] text-2xl" style={{ fontFamily: "Lora, serif", fontWeight: 600 }}>Grocery List</h1>
            {items.length > 0 && (
              <p className="text-[#9C8F8A] text-sm mt-0.5" style={{ fontFamily: "Outfit, sans-serif" }}>
                {items.length - checkedCount} remaining · {checkedCount} checked
              </p>
            )}
          </div>
          {/* Cart icon badge */}
          <div className="w-10 h-10 rounded-full bg-[#8A9B6E]/15 flex items-center justify-center">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke="#8A9B6E" strokeWidth="1.75" strokeLinejoin="round" />
              <path d="M3 6h18" stroke="#8A9B6E" strokeWidth="1.75" strokeLinecap="round" />
              <path d="M16 10a4 4 0 01-8 0" stroke="#8A9B6E" strokeWidth="1.75" strokeLinecap="round" />
            </svg>
          </div>
        </div>
      </div>

      {/* List or empty state */}
      {items.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center px-8 gap-5 pb-24">
          {/* Empty illustration */}
          <div className="relative w-28 h-28">
            <div className="absolute inset-0 rounded-full bg-[#8A9B6E]/10" />
            <div className="absolute inset-0 flex items-center justify-center">
              <svg width="56" height="56" viewBox="0 0 24 24" fill="none">
                <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" stroke="#8A9B6E" strokeWidth="1.4" strokeLinejoin="round" />
                <path d="M3 6h18" stroke="#8A9B6E" strokeWidth="1.4" strokeLinecap="round" />
                <path d="M16 10a4 4 0 01-8 0" stroke="#8A9B6E" strokeWidth="1.4" strokeLinecap="round" />
                <path d="M9 15h6M12 12v6" stroke="#C4B8B3" strokeWidth="1.4" strokeLinecap="round" />
              </svg>
            </div>
          </div>
          <div className="text-center">
            <p className="text-[#2B2420] text-[17px] font-semibold mb-2" style={{ fontFamily: "Lora, serif" }}>
              Your grocery list is empty
            </p>
            <p className="text-[#9C8F8A] text-sm leading-relaxed" style={{ fontFamily: "Outfit, sans-serif" }}>
              Tap "Add to List" on any recipe's{"\n"}ingredients to populate your list.
            </p>
          </div>
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto no-scrollbar px-5 pt-4 pb-36">
          {orderedGroups.map((category) => (
            <div key={category} className="mb-6">
              {/* Category header */}
              <div className="flex items-center gap-2 mb-2">
                <span className="text-[11px] font-bold text-[#9C8F8A] uppercase tracking-widest" style={{ fontFamily: "Outfit, sans-serif", letterSpacing: "0.08em" }}>
                  {category}
                </span>
                <div className="flex-1 h-px bg-[rgba(43,36,32,0.07)]" />
                <span className="text-[11px] text-[#C4B8B3]" style={{ fontFamily: "Outfit, sans-serif" }}>
                  {grouped[category].filter((i) => !i.checked).length}/{grouped[category].length}
                </span>
              </div>

              {/* Items */}
              <div className="bg-white rounded-2xl overflow-hidden shadow-[0_1px_8px_rgba(43,36,32,0.06)]">
                {grouped[category].map((item, idx) => (
                  <button
                    key={item.id}
                    onClick={() => onToggle(item.id)}
                    className={`w-full flex items-center gap-3 px-4 py-3.5 text-left transition-colors active:bg-[rgba(43,36,32,0.02)] ${idx < grouped[category].length - 1 ? "border-b border-[rgba(43,36,32,0.05)]" : ""}`}
                  >
                    {/* Checkbox */}
                    <div
                      className={`w-5 h-5 rounded-md flex-shrink-0 flex items-center justify-center border transition-all ${
                        item.checked ? "bg-[#8A9B6E] border-[#8A9B6E]" : "border-[rgba(43,36,32,0.18)] bg-white"
                      }`}
                    >
                      {item.checked && (
                        <svg width="11" height="11" viewBox="0 0 12 12" fill="none">
                          <path d="M2 6l3 3 5-5" stroke="white" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      )}
                    </div>

                    {/* Name */}
                    <span
                      className={`flex-1 text-sm leading-snug transition-colors ${item.checked ? "text-[#C4B8B3] line-through" : "text-[#2B2420]"}`}
                      style={{ fontFamily: "Outfit, sans-serif" }}
                    >
                      {item.name}
                    </span>

                    {/* Recipe source tag */}
                    <span
                      className="flex-shrink-0 text-[10px] font-medium px-2 py-0.5 rounded-full"
                      style={{
                        fontFamily: "Outfit, sans-serif",
                        background: "rgba(217,113,60,0.08)",
                        color: "#D9713C",
                        maxWidth: 90,
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {item.recipeTitle}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Clear checked footer */}
      {checkedCount > 0 && (
        <div className="absolute bottom-[72px] left-0 right-0 px-5 pb-3 pt-2 bg-[#FDF8F3]/90 backdrop-blur-sm">
          <button
            onClick={onClearChecked}
            className="w-full flex items-center justify-center gap-2 py-3 rounded-2xl border border-[rgba(43,36,32,0.12)] text-[#5C4F4A] text-sm font-semibold active:scale-[0.98] transition-transform"
            style={{ fontFamily: "Outfit, sans-serif" }}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
              <polyline points="3 6 5 6 21 6" stroke="#5C4F4A" strokeWidth="1.8" strokeLinecap="round" />
              <path d="M19 6l-1 14H6L5 6" stroke="#5C4F4A" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M10 11v6M14 11v6" stroke="#5C4F4A" strokeWidth="1.8" strokeLinecap="round" />
            </svg>
            Clear {checkedCount} checked item{checkedCount !== 1 ? "s" : ""}
          </button>
        </div>
      )}

      <TabBar active={activeTab} onSelect={onTab} />
    </div>
  );
}

// ─── App Root ─────────────────────────────────────────────────────────────────

export default function App() {
  const [screen, setScreen] = useState<Screen>("splash");
  const [activeTab, setActiveTab] = useState<Tab>("home");
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe>(RECIPES[0]);
  const [showAskAI, setShowAskAI] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);
  const [recipeSource, setRecipeSource] = useState<Screen>("dashboard");
  // Messaging state
  const [selectedUser, setSelectedUser] = useState<string>("naomi_cooks");
  const [chatBackScreen, setChatBackScreen] = useState<Screen>("conversations");
  const [prevScreen, setPrevScreen] = useState<Screen>("dashboard");

  // Grocery state
  const [groceryItems, setGroceryItems] = useState<GroceryItem[]>([]);

  const addToGrocery = (incoming: Omit<GroceryItem, "id" | "checked">[]) => {
    setGroceryItems((prev) => {
      const existing = new Set(prev.map((i) => i.name.toLowerCase().trim()));
      const fresh = incoming
        .filter((i) => !existing.has(i.name.toLowerCase().trim()))
        .map((i) => ({ ...i, id: `g${Date.now()}-${Math.random()}`, checked: false }));
      return [...prev, ...fresh];
    });
  };

  const toggleGroceryItem = (id: string) =>
    setGroceryItems((prev) => prev.map((i) => i.id === id ? { ...i, checked: !i.checked } : i));

  const clearCheckedGrocery = () =>
    setGroceryItems((prev) => prev.filter((i) => !i.checked));

  const handleTab = (t: Tab) => {
    setActiveTab(t);
    const map: Record<Tab, Screen> = {
      home: "dashboard",
      saved: "saved",
      history: "history",
      community: "community",
      profile: "profile",
      grocery: "grocery",
    };
    setScreen(map[t]);
    setShowAskAI(false);
  };

  const handleRecipe = (r: Recipe, source?: Screen) => {
    setSelectedRecipe(r);
    setRecipeSource(source ?? (activeTab === "community" ? "community" : "dashboard"));
    setScreen("recipe-overview");
  };

  const handleUser = (uploader: string, from: Screen) => {
    setSelectedUser(uploader);
    setPrevScreen(from);
    setScreen("user-profile");
  };

  const handleMessage = (uploader: string, from: Screen) => {
    setSelectedUser(uploader);
    setChatBackScreen(from);
    setScreen("chat");
  };

  const handleMessages = (from: Screen) => {
    setPrevScreen(from);
    setScreen("conversations");
  };

  const [adminItems, setAdminItems] = useState<AdminSubmission[]>(ADMIN_SUBMISSIONS);
  const [selectedAdminId, setSelectedAdminId] = useState<string>("s1");

  // Notifications state
  const [notifications, setNotifications] = useState<Notification[]>(SEED_NOTIFICATIONS);
  const [notifBackScreen, setNotifBackScreen] = useState<Screen>("dashboard");
  const unreadCount = notifications.filter((n) => !n.read).length;

  const [ratings, setRatings] = useState<Record<string, RecipeRatingData>>(SEED_RATINGS);
  const addRating = (recipeId: string, stars: number) => {
    setRatings((prev) => {
      const existing = prev[recipeId] ?? { average: 0, count: 0 };
      const newCount = existing.count + 1;
      const newAverage = (existing.average * existing.count + stars) / newCount;
      return { ...prev, [recipeId]: { average: Math.round(newAverage * 10) / 10, count: newCount } };
    });
  };

  const addNotification = (n: Omit<Notification, "id" | "read">) => {
    // Interaction note: fires when user likes, comments, saves, or starts cooking a recipe —
    // appended as a new unread entry simulating the original uploader's notification feed.
    setNotifications((prev) => [{ ...n, id: `n${Date.now()}`, read: false }, ...prev]);
  };

  const markAllRead = () => setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));

  const handleLogin = (adminRole: boolean) => {
    setIsAdmin(adminRole);
    setScreen(adminRole ? "admin-dashboard" : "dashboard");
  };

  const handleLogout = () => {
    setIsAdmin(false);
    setScreen("login");
  };

  const recipeBackScreen: Screen = (() => {
    if (recipeSource === "community") return "community";
    if (recipeSource === "user-profile") return "user-profile";
    if (activeTab === "saved") return "saved";
    return "dashboard";
  })();

  return (
    <div className="h-screen overflow-hidden bg-[#D4C9C0] flex items-center justify-center">
      {/* iPhone frame */}
      <div
        className="relative bg-[#FDF8F3] overflow-hidden shadow-[0_32px_80px_rgba(0,0,0,0.35),0_0_0_1px_rgba(0,0,0,0.1)]"
        style={{ width: 390, height: 844, borderRadius: 48 }}
      >
        {/* Notch */}
        <div
          className="absolute top-0 left-1/2 -translate-x-1/2 z-50 bg-black"
          style={{ width: 120, height: 30, borderBottomLeftRadius: 20, borderBottomRightRadius: 20 }}
        />

        {/* Screen content */}
        <div className="absolute inset-0 overflow-hidden">
          {screen === "splash" && (
            <SplashScreen onDone={() => setScreen("login")} />
          )}
          {screen === "login" && (
            <LoginScreen onLogin={handleLogin} onGuest={() => handleLogin(false)} />
          )}
          {screen === "dashboard" && (
            <DashboardScreen
              onRecipe={(r) => handleRecipe(r, "dashboard")}
              onGenerate={() => setScreen("ai-generate")}
              activeTab={activeTab}
              onTab={handleTab}
              onMessages={() => handleMessages("dashboard")}
              onNotifications={() => { setNotifBackScreen("dashboard"); setScreen("notifications"); }}
              unreadNotifications={unreadCount}
              ratings={ratings}
            />
          )}
          {screen === "ai-generate" && (
            <AIGenerateScreen
              onBack={() => setScreen("dashboard")}
              onGenerated={() => {
                setSelectedRecipe({ ...RECIPES[4], title: "AI-Generated Butter Chicken", cuisine: "Indian", isAIGenerated: true });
                setRecipeSource("dashboard");
                setScreen("recipe-overview");
              }}
            />
          )}
          {screen === "recipe-overview" && (
            <RecipeOverviewScreen
              recipe={selectedRecipe}
              onBack={() => setScreen(recipeBackScreen)}
              onStartCooking={() => setScreen("cook-mode")}
              onAddNotification={addNotification}
              onAddToGrocery={addToGrocery}
              rating={ratings[selectedRecipe?.id ?? ""]}
              onRate={(stars) => addRating(selectedRecipe?.id ?? "", stars)}
            />
          )}
          {screen === "cook-mode" && (
            <>
              <CookModeScreen
                onBack={() => setScreen("recipe-overview")}
                onAskAI={() => setShowAskAI(true)}
                onRate={(stars) => addRating(selectedRecipe?.id ?? "", stars)}
              />
              {showAskAI && (
                <AskAIOverlay
                  onClose={() => setShowAskAI(false)}
                  currentStep="Simmer the sauce"
                />
              )}
            </>
          )}
          {screen === "saved" && (
            <SavedScreen onRecipe={(r) => handleRecipe(r, "saved")} activeTab={activeTab} onTab={handleTab} ratings={ratings} />
          )}
          {screen === "history" && (
            <HistoryScreen activeTab={activeTab} onTab={handleTab} />
          )}
          {screen === "profile" && (
            <ProfileScreen
              activeTab={activeTab}
              onTab={handleTab}
              isAdmin={isAdmin}
              onAdmin={() => setScreen("admin-dashboard")}
              onLogout={handleLogout}
            />
          )}
          {screen === "community" && (
            <CommunityScreen
              onRecipe={(r) => handleRecipe(r, "community")}
              onUpload={() => setScreen("upload")}
              onUser={(u) => handleUser(u, "community")}
              activeTab={activeTab}
              onTab={handleTab}
              onMessages={() => handleMessages("community")}
              onNotifications={() => { setNotifBackScreen("community"); setScreen("notifications"); }}
              onAddNotification={addNotification}
              ratings={ratings}
            />
          )}
          {screen === "user-profile" && (
            <UserProfileScreen
              uploader={selectedUser}
              onBack={() => setScreen(prevScreen)}
              onMessage={() => handleMessage(selectedUser, "user-profile")}
              onRecipe={(r) => handleRecipe(r, "user-profile")}
              ratings={ratings}
            />
          )}
          {screen === "conversations" && (
            <ConversationsScreen
              onBack={() => setScreen(prevScreen)}
              onConversation={(u) => handleMessage(u, "conversations")}
            />
          )}
          {screen === "chat" && (
            <ChatScreen
              uploader={selectedUser}
              onBack={() => setScreen(chatBackScreen)}
            />
          )}
          {screen === "notifications" && (
            <NotificationsScreen
              notifications={notifications}
              onBack={() => setScreen(notifBackScreen)}
              onMarkAllRead={markAllRead}
              onRecipe={(recipeId) => {
                const r = [...RECIPES, ...COMMUNITY_RECIPES].find((x) => x.id === recipeId);
                if (r) handleRecipe(r, notifBackScreen);
              }}
            />
          )}
          {screen === "grocery" && (
            <GroceryListScreen
              items={groceryItems}
              onToggle={toggleGroceryItem}
              onClearChecked={clearCheckedGrocery}
              activeTab={activeTab}
              onTab={handleTab}
            />
          )}
          {screen === "upload" && (
            <UploadRecipeScreen
              onBack={() => setScreen("community")}
              onPublish={() => setScreen("community")}
            />
          )}
          {screen === "admin-dashboard" && (
            <AdminDashboardScreen
              onBack={() => setScreen("dashboard")}
              onManage={() => setScreen("admin-recipes")}
              items={adminItems}
            />
          )}
          {screen === "admin-recipes" && (
            <AdminRecipesScreen
              onBack={() => setScreen("admin-dashboard")}
              onDetail={(id) => { setSelectedAdminId(id); setScreen("admin-recipe-detail"); }}
              items={adminItems}
              setItems={setAdminItems}
            />
          )}
          {screen === "admin-recipe-detail" && (() => {
            const sub = adminItems.find((s) => s.id === selectedAdminId) ?? adminItems[0];
            const updateStatus = (status: AdminStatus, reason?: string) => {
              setAdminItems((prev) => prev.map((s) =>
                s.id === sub.id
                  ? {
                      ...s,
                      status,
                      // Prepend new reason to existing list so history is preserved
                      flagReasons: reason
                        ? [reason, ...(s.flagReasons ?? [])]
                        : s.flagReasons,
                    }
                  : s
              ));
            };
            const uploaderColor = COMMUNITY_USERS[sub.uploader]?.avatarColor ?? "#9C8F8A";
            return (
              <AdminRecipeDetailScreen
                submission={sub}
                onBack={() => setScreen("admin-recipes")}
                onApprove={() => {
                  updateStatus("visible");
                  setScreen("admin-recipes");
                }}
                onFlag={(reason) => {
                  updateStatus("flagged", reason);
                  setNotifications((prev) => [{
                    id: `n${Date.now()}`,
                    type: "flagged" as Notification["type"],
                    fromUser: sub.uploader,
                    avatarColor: uploaderColor,
                    recipeName: sub.title,
                    recipeId: sub.id,
                    timestamp: "Just now",
                    read: false,
                    adminReason: reason,
                  } as Notification & { adminReason: string }, ...prev]);
                  setScreen("admin-recipes");
                }}
                onRemove={(reason) => {
                  updateStatus("removed", reason);
                  setNotifications((prev) => [{
                    id: `n${Date.now()}`,
                    type: "removed" as Notification["type"],
                    fromUser: sub.uploader,
                    avatarColor: uploaderColor,
                    recipeName: sub.title,
                    recipeId: sub.id,
                    timestamp: "Just now",
                    read: false,
                    adminReason: reason,
                  } as Notification & { adminReason: string }, ...prev]);
                  setScreen("admin-recipes");
                }}
              />
            );
          })()}
        </div>

        {/* Home indicator */}
        <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-black/20 rounded-full z-50 pointer-events-none" />
      </div>
    </div>
  );
}
