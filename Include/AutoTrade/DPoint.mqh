class C_Point
{
   public:
      int pos;
      double price;
      datetime time;
   //methor
      void Clear();
};

void C_Point::Clear(void)
{
   pos = 0;
   price = 0;
   time = 0;
}