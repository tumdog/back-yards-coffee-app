class ChargesController < ApplicationController
  def create
    order = Stripe::Order.retrieve(params[:order_id])
    email = current_customer ? current_customer.email : customer_email(order.customer)
    token = params[:stripeToken]

    begin
      order.pay(source: token, email: email)
    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to '/cart'
    end

    carted_products = CartedProduct.my_carted(guest_or_customer_id)
    carted_products.map do |carted_product|
      carted_product.status = 'product ordered'
      carted_product.save
    end
    flash[:success] = 'Charge created!'
    redirect_to '/'
  end

  private

  def customer_email(stripe_customer_id)
    email = params[:stripeEmail]
    customer = Customer.find_by(stripe_customer_id: stripe_customer_id)
    customer.update(email: email)
    stripe_customer = Stripe::Customer.retrieve(stripe_customer_id)
    stripe_customer.email = email
    stripe_customer.save
    email
  end
end
