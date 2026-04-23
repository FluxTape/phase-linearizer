struct AllPass {
    c: f64,
    d: f64,
    wn_1: f64,
    wn_2: f64,
}

impl AllPass {
    pub fn new(r: f64, theta: f64) -> AllPass {
        let c = r * r;
        let d = -2. * r * theta.cos();
        AllPass {c, d, wn_1: 0., wn_2: 0.}
    }

    pub fn step(&mut self, input: f64) -> f64 {
        let wn_0 = input - self.d * self.wn_1 - self.c * self.wn_2;
        let y = self.c * wn_0 + self.d * self.wn_1 + self.wn_2;
        self.wn_2 = self.wn_1;
        self.wn_1 = wn_0;
        y
    }

    pub fn step_mul_add(&mut self, input: f64) -> f64 {
        let dwn_1 = self.d * self.wn_1;
        let wn_0 = input - self.c.mul_add(self.wn_2, dwn_1);
        let y = self.c.mul_add(wn_0, dwn_1) + self.wn_2;
        self.wn_2 = self.wn_1;
        self.wn_1 = wn_0;
        y
    }
}